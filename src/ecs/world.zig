const std = @import("std");
const ECS = @import("zecs").ECS;
const Components = @import("components.zig");
const AssetManager = @import("../asset_manager/asset_manager.zig").AssetManager;
const Input = @import("../input.zig").Input;

const WorldComponents = union(enum) {
    Transform: Components.Transform,
    Rigidbody: Components.Rigidbody,
    Rotation: Components.Rotation,
    MeshRenderer: Components.MeshRenderer,
    Collider: Components.Collider,
    TagApple: Components.TagApple,
    TagSpike: Components.TagSpike,
};

const Meta = struct {
    drawColliders: bool,
    drawGismos: bool,

    pub fn init() Meta {
        return .{
            .drawColliders = false,
            .drawGismos = false,
        };
    }
};

const WorldState = struct {
    meta: Meta,
    playerInput: Input,
    applesAlive: u16,
    applesEaten: u16,
    spikes: u16,

    pub fn init(allocator: std.mem.Allocator) WorldState {
        _ = allocator;
        return .{
            .playerInput = Input.init(),
            .applesAlive = 0,
            .applesEaten = 0,
            .spikes = 0,
            .meta = Meta.init(),
        };
    }
    pub fn deinit(self: *WorldState) void {
        _ = self;
    }
};

pub const World = ECS(WorldComponents, .{ .State = WorldState, .AssetManager = AssetManager });
