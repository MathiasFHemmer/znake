const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");

pub fn check_apple_eat(player: Entity, world: *World) void {
    const query = world.query(struct { transform: Components.Transform }).sets;
    const playerTransform = world.getComponent(player, Components.Transform).?;

    for (query.transform.dense.items, query.transform.entities.items) |*transform, entity| {
        if (entity == player) continue;

        if (ast_check(playerTransform, transform)) {
            std.debug.print("IS CLOSE (dst: {d})\n", .{playerTransform.position.distance(transform.position)});
            // world.removeEntity(entity);
            // playerTransform.scale = playerTransform.scale.addValue(0.1);
            // world.state.applesAlive -= 1;
        }
    }
}

fn ast_check(t1: *Components.Transform, t2: *Components.Transform) bool {
    const t1Half = t1.position.subtract(t1.scale.scale(0.5));
    const t1Rect = rl.Rectangle.init(t1Half.x, t1Half.z, t1Half.x + t1.scale.x, t1Half.z + t1.scale.z);

    const t2Half = t2.position.subtract(t2.scale.scale(0.5));
    const t2Rect = rl.Rectangle.init(t2Half.x, t2Half.z, t2Half.x + t2.scale.x, t2Half.z + t2.scale.z);

    return t2Rect.checkCollision(t1Rect);
}
