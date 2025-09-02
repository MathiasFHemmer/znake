const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");

var curSpeed: f32 = 0;
var acceleration: f32 = 10;
const maxVel: f32 = 10;

pub fn playerControllerUpdate(world: *World, player: Entity, dt: f32) void {
    const rotation = world.getComponent(player, Components.Rotation);
    const rb = world.getComponent(player, Components.Rigidbody);

    if (rl.isMouseButtonPressed(.left)) {
        world.removeEntity(player);
    }
    if (rotation) |rot| {
        if (rl.isKeyDown(rl.KeyboardKey.j)) {
            rot.a += 100 * math.DEG2RAD * dt;
        }
        if (rl.isKeyDown(rl.KeyboardKey.l)) {
            rot.a -= 100 * math.DEG2RAD * dt;
        }

        if (rb) |_rb| {
            if (rl.isKeyDown(rl.KeyboardKey.i)) {
                curSpeed += acceleration * dt;
            } else if (rl.isKeyDown(rl.KeyboardKey.k)) {
                curSpeed -= acceleration * dt;
            } else {
                curSpeed -= acceleration * dt * -std.math.sign(curSpeed);
            }
            curSpeed = std.math.clamp(curSpeed, -maxVel, maxVel);

            _rb.velocity.x = curSpeed;
            _rb.velocity.y = 0;
            _rb.velocity.z = curSpeed;
        }
    }
}
