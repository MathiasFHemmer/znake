const std = @import("std");
const rl = @import("raylib");
const rlx = @import("../../rayext.zig");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const math = @import("../../math/math.zig");
//TODO:
// Get some info about extrapolation/interpolation
// https://kirbysayshi.com/2013/09/24/interpolated-physics-rendering.html
const drawCollider = false;
const drawGismos = true;

pub fn drawMeshSystem(world: *World, alphaDt: f32) void {
    var query = world.query(struct { meshRender: Components.MeshRenderer, transform: Components.Transform }).sets;
    for (query.meshRender.dense.items, query.meshRender.entities.items) |*mesh, entity| {
        const transform: *Components.Transform = query.transform.getUnsafe(entity);

        // Interpolate position
        const finalPosition = (transform.position.scale(alphaDt)).add(transform.position.scale(1 - alphaDt));

        // Interpolate rotation
        const rot = transform.oldRotation.nlerp(transform.rotation, 1 - @exp(-alphaDt));

        mesh.drawMesh(finalPosition, transform.scale, rot, &world.assetManager);

        if (world.state.meta.drawColliders) {
            if (world.getComponent(entity, Components.Collider)) |col| col.drawCollider(transform);
        }
        if (world.state.meta.drawGismos) {
            rl.drawLine3D(transform.position, transform.position.add(transform.worldForward()), rl.Color.blue);
            rl.drawLine3D(transform.position, transform.position.add(transform.worldRight()), rl.Color.red);
            rl.drawLine3D(transform.position, transform.position.add(transform.worldUp()), rl.Color.green);
        }
    }
}
