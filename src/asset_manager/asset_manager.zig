const std = @import("std");
const rl = @import("raylib");
const logger = std.log.scoped(.asset_manager);
const AssetStore = @import("asset_store.zig").AssetStore;
const MeshStore = @import("stores/mesh_store.zig").MeshStore;
const ShaderStore = @import("stores/shader_store.zig").ShaderStore;

// Default Assets to load
const Apple = @import("../ecs/entities/apple.zig");
const Snake = @import("../ecs/entities/snake.zig");
const Spike = @import("../ecs/entities/spike.zig");

pub const AssetManager = struct {
    const Self = @This();

    meshStore: MeshStore,
    shaderStore: ShaderStore,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var self = Self{
            .meshStore = MeshStore.init(allocator),
            .shaderStore = try ShaderStore.init(allocator),
        };

        try Snake.generateDefaults(allocator, &self);
        try Apple.generateDefaults(allocator, &self);
        try Spike.generateDefaults(allocator, &self);
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.meshStore.deinit();
        self.shaderStore.deinit();
    }
};
