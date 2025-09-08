const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");

pub fn playerMove(world: *World, dt: f32) void {
    var query = world.query(struct { transform: Components.Transform, rigidbody: Components.Rigidbody, rotation: Components.Rotation }).sets;
    for (query.transform.dense.items, query.transform.entities.items) |*t, entity| {
        if (entity != 1) continue;
        const vel = query.rigidbody.getUnsafe(entity).velocity;
        const rot = query.rotation.getUnsafe(entity);

        t.oldPosition = t.position;
        t.oldRotation = t.rotation;
        t.oldScale = t.scale;

        var pos = t.position;

        t.rotation = rl.Quaternion.fromAxisAngle(.init(0, 1, 0), rot.a).normalize();
        const dir = vel.rotateByQuaternion(t.rotation).scale(dt);
        t.position = pos.add(dir);
    }
}
