const std = @import("std");
const rl = @import("raylib");
const logger = std.log.scoped(.asset_manager);
const AssetStore = @import("asset_store.zig").AssetStore;
const MeshStore = @import("stores/mesh_store.zig").MeshStore;
const ShaderStore = @import("stores/shader_store.zig").ShaderStore;

pub const AssetManager = struct {
    const Self = @This();

    meshStore: MeshStore,
    shaderStore: ShaderStore,

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .meshStore = MeshStore.init(allocator),
            .shaderStore = try ShaderStore.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.meshStore.deinit();
        self.shaderStore.deinit();
    }
};
