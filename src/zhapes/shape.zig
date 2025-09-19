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

    pub fn init(r: f32) Sphere {
        return Sphere{
            .radius = r,
        };
    }

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

pub const Manifest = struct { penetration: rl.Vector3 };

pub fn checkCollision(pos1: rl.Vector3, pos2: rl.Vector3, s1: Shape, s2: Shape) ?Manifest {
    if (s1 == Shape.sphere and s2 == Shape.sphere) {
        return CircleVsCricle(pos1, pos2, s1.sphere, s2.sphere);
    }
    return null;
}

pub fn CircleVsCricle(pos1: rl.Vector3, pos2: rl.Vector3, s1: Sphere, s2: Sphere) ?Manifest {
    const len = pos1.subtract(pos2).length();
    const radius = s1.radius + s2.radius;

    if (len <= radius) {
        return Manifest{
            .penetration = pos1.subtract(pos2).normalize().scale(len - radius),
        };
    }
    return null;
}
