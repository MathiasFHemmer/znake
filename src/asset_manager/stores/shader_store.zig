const std = @import("std");
const rl = @import("raylib");

const logger = std.log.scoped(.shader_store);

var DEFAULT_SHADER_VS = @embedFile("shaders/default.vs");
var DEFAULT_SHADER_FS = @embedFile("shaders/default.fs");

pub const ShaderStore = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    shaders: std.StringHashMap(Entry),

    const Entry = struct {
        asset: rl.Shader,
        ref_count: usize,
    };

    pub fn init(allocator: std.mem.Allocator) !Self {
        var self = Self{
            .allocator = allocator,
            .shaders = std.StringHashMap(Entry).init(allocator),
        };

        logger.info("Initializing default shaders", .{});
        try self.shaders.put("default", .{
            .asset = try rl.loadShaderFromMemory(DEFAULT_SHADER_VS, DEFAULT_SHADER_FS),
            .ref_count = 0,
        });
        return self;
    }

    pub fn deinit(self: *Self) void {
        var it = self.shaders.valueIterator();
        while (it.next()) |entry| {
            unloadShader(entry.asset);
        }

        self.shaders.deinit();
    }

    pub fn add(self: *Self, key: []const u8, shader: rl.Shader) !*rl.Shader {
        logger.info("Adding new Shader to store", .{});
        if (self.shaders.contains(key)) {
            std.debug.panic("Shader {s} is already present on store!", .{key});
            return error.AssetKeyAlreadyExists;
        }

        try self.shaders.put(key, .{
            .asset = shader,
            .ref_count = 1,
        });
        const newMesh = try self.get(key);
        return newMesh;
    }

    pub fn get(self: *Self, key: []const u8) !*rl.Shader {
        const entry = self.shaders.getPtr(key);
        if (entry) |e| {
            e.ref_count += 1;
            return &e.asset;
        }
        std.debug.panic("Could not find shader {s}", .{key});
        return error.AssetKeyNotFound;
    }
};

pub fn unloadShader(shader: rl.Shader) void {
    shader.unload();
}
