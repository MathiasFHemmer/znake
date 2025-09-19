const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");
const shapes = @import("../../zhapes/shape.zig");

pub fn check_apple_eat(player: Entity, world: *World) void {
    const query = world.query(struct { transform: Components.Transform, collider: Components.Collider }).sets;
    const playerTransform = world.getComponent(player, Components.Transform).?;
    const playerRigidbody: *Components.Rigidbody = world.getComponent(player, Components.Rigidbody).?;
    const playerCollider = world.getComponent(player, Components.Collider).?;

    for (query.transform.dense.items, query.transform.entities.items) |*transform, entity| {
        if (entity == player) continue;

        const coll = world.getComponent(entity, Components.Collider);
        if (coll == null) continue;

        if (shapes.checkCollision(playerTransform.position, transform.position, playerCollider.shape, coll.?.shape)) |manifest| {
            if (world.getComponent(entity, Components.TagApple) != null) {
                world.markForRemoval(entity);
                world.state.applesAlive -= 1;
                world.state.applesEaten += 1;
                continue;
            }
            playerTransform.position = playerTransform.position.subtract(manifest.penetration);
            // playerRigidbody.velocity = playerRigidbody.velocity.subtractValue(rl.Vector3.dotProduct(manifest.penetration, playerRigidbody.velocity));
            _ = playerRigidbody;
        }
    }
    world.flushRemoval();
}
