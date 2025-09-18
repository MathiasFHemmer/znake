const std = @import("std");
const rl = @import("raylib");

pub const ShapeType = enum {
    cube,
    sphere,
};

pub const Cube = struct {
    length: rl.Vector3,

    pub fn unit() Cube {
        return Cube{
            .length = .one(),
        };
    }
};

pub const Sphere = struct {
    radius: f32,

    pub fn unit() Sphere {
        return Sphere{
            .radius = 0.5,
        };
    }
};

pub const Shape = union(ShapeType) {
    cube: Cube,
    sphere: Sphere,
};

pub fn checkCollision(pos1: rl.Vector3, pos2: rl.Vector3, s1: Shape, s2: Shape) bool {
    if (s1 == Shape.sphere and s2 == Shape.sphere) {
        return pos1.subtract(pos2).lengthSqr() <= std.math.pow(f32, s1.sphere.radius + s2.sphere.radius, 2);
    }
    return false;
}
