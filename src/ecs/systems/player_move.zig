const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("zecs").Entity;
const math = @import("../../math/math.zig");

pub fn playerMove(world: *World, playerEnitity: Entity, dt: f32) void {
    const t = world.getComponent(playerEnitity, Components.Transform).?;
    const vel = world.getComponent(playerEnitity, Components.Rigidbody).?.velocity;
    const rot = world.getComponent(playerEnitity, Components.Rotation).?;

    t.oldPosition = t.position;
    t.oldRotation = t.rotation;
    t.oldScale = t.scale;

    var pos = t.position;

    t.rotation = rl.Quaternion.fromAxisAngle(.init(0, 1, 0), rot.a).normalize();
    const dir = vel.rotateByQuaternion(t.rotation).scale(dt);
    t.position = pos.add(dir);
}
