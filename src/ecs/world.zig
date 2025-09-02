const ECS = @import("ecs.zig").ECS;
const Components = @import("components.zig");
const AssetManager = @import("../asset_manager/asset_manager.zig").AssetManager;

const WorldComponents = struct {
    Transform: Components.Transform,
    Rigidbody: Components.Rigidbody,
    Rotation: Components.Rotation,
    MeshRenderer: Components.MeshRenderer,
};

pub const WorldAssetManager = AssetManager;
pub const World = ECS(WorldComponents);
