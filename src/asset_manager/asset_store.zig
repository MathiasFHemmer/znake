const std = @import("std");
const logger = std.log.scoped(.asset_store);

pub fn AssetStore(comptime Asset: type) type {
    return struct {
        const Self = @This();
        const Key = []const u8;

        allocator: std.mem.Allocator,
        assets: std.StringHashMap(Entry),
        loadFn: *const fn (std.mem.Allocator, []const u8) anyerror!Asset,
        loadFromMFn: *const fn (std.mem.Allocator, []const u8) anyerror!Asset,
        unloadFn: *const fn (std.mem.Allocator, Asset) void,

        const Entry = struct {
            asset: Asset,
            ref_count: usize,
        };

        pub fn init(allocator: std.mem.Allocator, loadFn: *const fn (std.mem.Allocator, []const u8) anyerror!Asset, unloadFn: *const fn (std.mem.Allocator, Asset) void) Self {
            return .{
                .allocator = allocator,
                .assets = std.StringHashMap(Entry).init(allocator),
                .loadFn = loadFn,
                .unloadFn = unloadFn,
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.assets.valueIterator();
            while (it.next()) |entry| {
                self.unloadFn(self.allocator, entry.asset);
            }

            self.assets.deinit();
        }

        pub fn get(self: *Self, key: Key) !*Asset {
            const entry = self.assets.getPtr(key);
            if (entry) |e| {
                e.ref_count += 1;
                return &e.asset;
            }
            std.debug.panic("Could not find asset {s}", .{key});
            return error.AssetKeyNotFound;
        }

        pub fn load(self: *Self, key: Key) !*Asset {
            if (self.assets.contains(key)) {
                std.debug.panic("Asset {s} is already present on store!", .{key});
                return error.AssetKeyAlreadyExists;
            }

            const asset = try self.loadFn(self.allocator, key);
            const entry = Entry{
                .asset = asset,
                .ref_count = 1,
            };
            try self.assets.put(key, entry);
            logger.info("Loaded asset: {s}", .{key});
            return try self.get(key);
        }

        pub fn loadFromMemory(self: *Self, key: Key) !*Asset {
            if (self.assets.contains(key)) {
                std.debug.panic("Asset {s} is already present on store!", .{key});
                return error.AssetKeyAlreadyExists;
            }

            const asset = try self.loadFn(self.allocator, key);
            const entry = Entry{
                .asset = asset,
                .ref_count = 1,
            };
            try self.assets.put(key, entry);
            logger.info("Loaded asset: {s}", .{key});
            return try self.get(key);
        }

        pub fn set(self: *Self, key: Key, asset: Asset) !*Asset {
            if (self.assets.contains(key)) {
                std.debug.panic("Asset {s} is already present on store!", .{key});
                return error.AssetKeyAlreadyExists;
            }

            const entry = Entry{
                .asset = asset,
                .ref_count = 1,
            };
            try self.assets.put(key, entry);
            logger.info("Set asset: {s}", .{key});
            return try self.get(key);
        }
    };
}
