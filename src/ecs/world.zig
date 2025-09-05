const ECS = @import("ecs.zig").ECS;
const Components = @import("components.zig");
const AssetManager = @import("../asset_manager/asset_manager.zig").AssetManager;
const Input = @import("../input.zig").Input;

const WorldComponents = struct {
    Transform: Components.Transform,
    Rigidbody: Components.Rigidbody,
    Rotation: Components.Rotation,
    MeshRenderer: Components.MeshRenderer,
};

const WorldState = struct {
    playerInput: Input,
};

pub const WorldAssetManager = AssetManager;
pub const World = ECS(WorldComponents, WorldState);
