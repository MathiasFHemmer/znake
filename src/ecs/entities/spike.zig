const std = @import("std");
const rl = @import("raylib");
const WorldEnv = @import("../world.zig");
const Components = @import("../components.zig");
const Entity = @import("../ecs.zig").Entity;

pub fn create(world: *WorldEnv.World, position: rl.Vector3) !Entity {
    const entity = world.createEntity();

    const mesh = world.assetManager.meshStore.get("SPIKE") catch @panic("Default apple mesh not found, did you call `generateDefaults`?");
    const shader = world.assetManager.shaderStore.get("default") catch @panic("Default shader not found, did you call `generateDefaults`?");

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    var mass = rand.float(f32);
    if (mass <= 0.5) mass = 0 else mass *= 25;

    const coll_size = if (mass != 0) mass / 10 else 0.5;

    var t = Components.Transform.init(position);
    if (mass != 0) t.scale = t.scale.scale(mass / 10);
    world.addComponent(entity, t);
    world.addComponent(entity, try Components.MeshRenderer.init(mesh, shader));
    world.addComponent(entity, Components.Collider.init(.{ .sphere = .init(coll_size) }));
    world.addComponent(entity, Components.Rigidbody.init(mass));

    return entity;
}

pub fn generateDefaults(allocator: std.mem.Allocator, assetManager: *WorldEnv.WorldAssetManager) !void {
    _ = allocator;
    const mesh = rl.genMeshPlane(1, 1, 1, 1);
    _ = try assetManager.meshStore.add("SPIKE", mesh);
}
