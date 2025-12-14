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

const logger = std.log.scoped(.collision_solver);

pub fn collision_solver(world: *World) void {
    const query = world.query(struct { transform: Components.Transform, collider: Components.Collider }).sets;

    for (query.collider.dense.items, query.collider.entities.items, 0..) |*collider, entity, idx| {
        for ((idx + 1)..query.collider.dense.items.len) |other_idx| {
            const other_collider = query.collider.dense.items[other_idx];
            const other_entity = query.collider.entities.items[other_idx];

            const transform = world.getComponent(entity, Components.Transform).?;
            const other_transform = world.getComponent(other_entity, Components.Transform).?;

            var default_rb = Components.Rigidbody.init(1);
            var rigidbody = world.getComponent(entity, Components.Rigidbody) orelse &default_rb;
            var other_rigidbody = world.getComponent(other_entity, Components.Rigidbody) orelse &default_rb;

            if (shapes.checkCollision(transform.position, other_transform.position, collider.shape, other_collider.shape)) |manifest| {
                logger.debug("Mass 1 {any} Mass 2 {any}", .{ rigidbody.mass, other_rigidbody.mass });

                const f1: f32 = if (rigidbody.mass > 0.01) 1.0 / rigidbody.mass else 0.0;
                const f2: f32 = if (other_rigidbody.mass > 0.01) 1.0 / other_rigidbody.mass else 0.0;
                const rv = other_rigidbody.velocity.subtract(rigidbody.velocity);
                const velAlongNormal = rv.dotProduct(manifest.penetration);
                const j = -(1.0 + 1.0) * velAlongNormal / (f1 + f2);
                const impulse = manifest.penetration.normalize().scale(j);

                const percent = 1; // usually 20% of penetration
                const slop = 0.01; // tolerance
                const correction = manifest.penetration.normalize().scale(percent * @max(manifest.penetration.length() - slop, 0.0) / (f1 + f2));

                if (f1 != 0) transform.position = transform.position.subtract(correction.scale(f1));
                if (f2 != 0) other_transform.position = other_transform.position.add(correction.scale(f2));

                if (f1 != 0) rigidbody.velocity = rigidbody.velocity.subtract(impulse.scale(f1));
                if (f2 != 0) other_rigidbody.velocity = other_rigidbody.velocity.add(impulse.scale(f2));
            }
        }
    }
}
