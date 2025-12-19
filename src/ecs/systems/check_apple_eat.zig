const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("zecs").Entity;
const math = @import("../../math/math.zig");
const shapes = @import("../../zhapes/shape.zig");

pub fn check_apple_eat(player: Entity, world: *World) void {
    const query = world.query(struct { transform: Components.Transform, collider: Components.Collider }).sets;
    const playerTransform = world.getComponent(player, Components.Transform).?;
    const playerCollider = world.getComponent(player, Components.Collider).?;

    for (query.transform.dense.items, query.transform.entities.items) |*transform, entity| {
        if (entity == player) continue;

        const coll = world.getComponent(entity, Components.Collider);
        if (coll == null) continue;

        if (shapes.checkCollision(playerTransform.position, playerTransform.rotation, transform.position, transform.rotation, playerCollider.shape, coll.?.shape)) |_| {
            if (world.getComponent(entity, Components.TagApple) != null) {
                world.markForRemoval(entity);
                world.state.applesAlive -= 1;
                world.state.applesEaten += 1;
                continue;
            }
        }
    }
    world.flushRemoval();
}
