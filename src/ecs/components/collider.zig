const std = @import("std");
const rl = @import("raylib");

const ColliderShapeType = enum {
    square,
    circle,
};

const ColliderShape = union(ColliderShapeType) {
    square: struct { position: rl.Vector3, length: rl.Vector3 },
    circle: f32,
};

pub const Collider = struct {
    shape: ColliderShape,

    pub fn init(shape: ColliderShape) Collider {
        return .{
            .shape = shape,
        };
    }
};
