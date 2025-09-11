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

pub fn drawMeshSystem(world: *World, alphaDt: f32) void {
    var query = world.query(struct { meshRender: Components.MeshRenderer, transform: Components.Transform }).sets;
    for (query.meshRender.dense.items, query.meshRender.entities.items) |*mesh, entity| {
        const trans: *Components.Transform = query.transform.getUnsafe(entity);

        // Interpolate position
        const finalPosition = (trans.position.scale(alphaDt)).add(trans.position.scale(1 - alphaDt));

        // Interpolate rotation
        const rot = trans.oldRotation.nlerp(trans.rotation, 1 - @exp(-alphaDt));

        mesh.drawMesh(finalPosition, trans.scale, rot, trans.worldForward());

        const collider = world.getComponent(entity, Components.Collider);
        if (collider) |col| {
            switch (col.shape) {
                .square => |sqr| rlx.drawCubeWiresV(sqr.position.add(trans.position), sqr.length, trans.rotation, rl.Color.dark_green),
                .circle => unreachable,
            }
        }
    }
}
