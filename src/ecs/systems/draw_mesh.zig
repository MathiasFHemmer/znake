const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;

pub fn drawMeshSystem(world: *World, alphaDt: f32) void {
    var query = world.query(struct { meshRender: Components.MeshRenderer, transform: Components.Transform }).sets;
    for (query.meshRender.dense.items, query.meshRender.entities.items) |*mesh, entity| {
        const trans = query.transform.getUnsafe(entity);

        // Extrapolate position
        const deltaPos = trans.position.subtract(trans.oldPosition);
        const i_pos = trans.position.add(deltaPos.scale(alphaDt));

        // Extrapolate rotation
        const rot = trans.rotation.multiply(trans.oldRotation.invert());
        var ang: f32 = undefined;
        var axis: rl.Vector3 = undefined;
        rot.toAxisAngle(&axis, &ang);
        const i_quaternion = trans.rotation.multiply(rl.Quaternion.fromAxisAngle(axis, ang));
        _ = i_quaternion;

        mesh.drawMesh(i_pos, trans.scale, trans.oldRotation.nlerp(trans.rotation, alphaDt), trans.worldForward());
    }
}
