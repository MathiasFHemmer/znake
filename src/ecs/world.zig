const ECS = @import("ecs.zig").ECS;
const Components = @import("components.zig");
const AssetManager = @import("../asset_manager/asset_manager.zig").AssetManager;
const Input = @import("../input.zig").Input;

const WorldComponents = struct {
    Transform: Components.Transform,
    Rigidbody: Components.Rigidbody,
    Rotation: Components.Rotation,
    MeshRenderer: Components.MeshRenderer,
    Collider: Components.Collider,
};

const WorldState = struct {
    playerInput: Input,
    applesAlive: u16,

    pub fn init() WorldState {
        return .{
            .playerInput = Input.init(),
            .applesAlive = 0,
        };
    }
};

pub const WorldAssetManager = AssetManager;
pub const World = ECS(WorldComponents, WorldState);
