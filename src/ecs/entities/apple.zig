const std = @import("std");
const rl = @import("raylib");
const WorldEnv = @import("../world.zig");
const AssetManager = @import("../../asset_manager/asset_manager.zig").AssetManager;
const Components = @import("../components.zig");
const Entity = @import("zecs").Entity;

pub fn create(world: *WorldEnv.World, position: rl.Vector3) !Entity {
    const entity = world.createEntity();

    // const mesh = world.assetManager.meshStore.get("APPLE") catch @panic("Default apple mesh not found, did you call `generateDefaults`?");
    // const shader = world.assetManager.shaderStore.get("default") catch @panic("Default shader not found, did you call `generateDefaults`?");

    world.addComponent(entity, Components.Transform.init(position));
    world.addComponent(entity, try Components.MeshRenderer.init("APPLE", "default"));
    world.addComponent(entity, Components.Collider.init(.{ .sphere = .unit() }));
    world.addComponent(entity, Components.TagApple{ .a = 8 });

    return entity;
}

pub fn generateDefaults(allocator: std.mem.Allocator, assetManager: *AssetManager) !void {
    _ = allocator;
    const mesh = rl.genMeshPlane(1, 1, 1, 1);
    _ = try assetManager.meshStore.add("APPLE", mesh);
}
