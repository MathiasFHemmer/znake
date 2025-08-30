const std = @import("std");
const rl = @import("raylib");
const logger = std.log.scoped(.asset_manager);

// https://github.com/raysan5/raylib/wiki/raylib-generic-uber-shader-and-custom-shaders
pub fn rlLoadShaderWrapper(allocator: std.mem.Allocator, path: []const u8) !rl.Shader {
    _ = allocator;
    var vsFileNameBuf: [256]u8 = undefined;
    var fsFileNameBuf: [256]u8 = undefined;

    const vsFileName = std.fmt.bufPrintZ(&vsFileNameBuf, "{s}.vs", .{path}) catch @panic("Failed to format vertex shader filename");
    const fsFileName = std.fmt.bufPrintZ(&fsFileNameBuf, "{s}.fs", .{path}) catch @panic("Failed to format fragment shader filename");
    const shader = rl.loadShader(vsFileName, fsFileName) catch |err| {
        logger.err("Failed to load shader at path {s}: {any}", .{ path, err });
        return err;
    };
    if (shader.id == 0) {
        @panic("Failed to load shader");
    }
    return shader;
}
pub fn rlUnloadShaderWrapper(allocator: std.mem.Allocator, shader: rl.Shader) void {
    _ = allocator;
    rl.unloadShader(shader);
}

pub fn AssetStore(comptime Asset: type) type {
    return struct {
        const Self = @This();
        const Key = []const u8;

        allocator: std.mem.Allocator,
        assets: std.StringHashMap(Entry),
        load_fn: *const fn (allocator: std.mem.Allocator, key: Key) anyerror!Asset,
        unload_fn: *const fn (allocator: std.mem.Allocator, asset: Asset) void,

        const Entry = struct {
            asset: ?Asset,
            ref_count: usize,
            loading: bool = false,
        };

        pub fn init(
            allocator: std.mem.Allocator,
            load_fn: *const fn (allocator: std.mem.Allocator, key: Key) anyerror!Asset,
            unload_fn: *const fn (allocator: std.mem.Allocator, asset: Asset) void,
        ) Self {
            return .{
                .allocator = allocator,
                .assets = std.StringHashMap(Entry).init(allocator),
                .load_fn = load_fn,
                .unload_fn = unload_fn,
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.assets.iterator();
            while (it.next()) |entry| {
                if (entry.value_ptr.ref_count != 0) {
                    logger.err("Warning: Asset with key {s} has non-zero ref count {d} during AssetStore deinit", .{ entry.key_ptr, entry.value_ptr.ref_count });
                }
                if (entry.value_ptr.asset) |asset| {
                    self.unload_fn(self.allocator, asset);
                }
            }
            self.assets.deinit();
        }

        pub fn prepare(self: *Self, key: Key) !void {
            logger.info("Asset({s}) {s} queued for loading", .{ @typeName(Asset), key });
            try self.assets.put(key, .{
                .asset = null,
                .ref_count = 1,
            });
        }

        pub fn get(self: *Self, key: Key) !*Asset {
            var entry = try self.assets.getOrPut(key);
            if (!entry.found_existing) {
                // New asset, load it immediately
                logger.info("Asset({s}) {s} is getting static loaded", .{ @typeName(Asset), key });
                const asset = try self.load_fn(self.allocator, key);
                entry.value_ptr.* = .{
                    .asset = asset,
                    .ref_count = 1,
                };
                return &entry.value_ptr.asset.?;
            }

            // Existing entry
            if (entry.value_ptr.asset == null) {
                // Lazy load the asset
                entry.value_ptr.loading = true;
                logger.info("Asset({s}) {s} is getting lazy loaded", .{ @typeName(Asset), key });
                const asset = try self.load_fn(self.allocator, key);
                entry.value_ptr.asset = asset;
                entry.value_ptr.loading = false;
            }

            entry.value_ptr.ref_count += 1;
            return &entry.value_ptr.asset.?;
        }

        pub fn release(self: *Self, key: Key) void {
            if (self.assets.getPtr(key)) |entry| {
                if (entry.ref_count > 0) {
                    entry.ref_count -= 1;
                }

                if (entry.ref_count == 0 and entry.asset != null) {
                    logger.info("Asset({s}) {s} has no reference left and is getting deallocated", .{ @typeName(Asset), key });
                    self.unload_fn(self.allocator, entry.asset.?);
                    _ = self.assets.remove(key);
                }
            }
        }

        pub fn isLoaded(self: *Self, key: Key) bool {
            if (self.assets.get(key)) |entry| {
                return entry.asset != null and !entry.loading;
            }
            return false;
        }

        pub fn preload(self: *Self, key: Key) !void {
            _ = try self.get(key);
            self.release(key); // Decrement the ref count added by get
        }
    };
}
