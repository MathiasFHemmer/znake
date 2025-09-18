const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");

const rotationSpeed = 5.0;

const movementResponse = 10.0;
const movementSpeed: f32 = 5.0;
const slowMovementSpeed: f32 = 0.2;

pub fn playerControllerUpdate(world: *World, player: Entity, dt: f32) void {
    const rotation = world.getComponent(player, Components.Rotation).?;
    const rb = world.getComponent(player, Components.Rigidbody).?;

    if (rl.isMouseButtonPressed(.left)) {
        world.removeEntity(player);
    }

    const requestedMovement = world.state.playerInput.movement;
    rotation.a += requestedMovement.x * rotationSpeed * dt;
    const targetVelocity = rl.Vector3.init(0, 0, requestedMovement.y * if (world.state.playerInput.slow == true) slowMovementSpeed else movementSpeed);
    rb.velocity = rb.velocity.lerp(targetVelocity, 1 - @exp(-movementResponse * dt));
}
