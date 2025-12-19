const std = @import("std");
const rl = @import("raylib");

pub const ShapeType = enum {
    cube,
    sphere,
};

pub const Cube = struct {
    length: rl.Vector3,

    pub fn init(scale: f32) Cube {
        return Cube{
            .length = .init(scale, scale, scale),
        };
    }

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

pub fn checkCollision(pos1: rl.Vector3, rot1: rl.Quaternion, pos2: rl.Vector3, rot2: rl.Quaternion, s1: Shape, s2: Shape) ?Manifest {
    if (s1 == Shape.sphere and s2 == Shape.sphere) {
        return CircleVsCricle(pos1, pos2, s1.sphere, s2.sphere);
    }
    if (s1 == Shape.cube and s2 == Shape.cube) {
        return CubeVsCube(pos1, rot1, s1.cube, pos2, rot2, s2.cube);
    }
    if (s1 == Shape.sphere and s2 == Shape.cube) {
        return CircleVsCube(pos1, s1.sphere, pos2, rot2, s2.cube);
    }
    if (s1 == Shape.cube and s2 == Shape.sphere) {
        const manifest = CircleVsCube(pos2, s2.sphere, pos1, rot1, s1.cube);
        if (manifest) |m| {
            return Manifest{ .penetration = m.penetration.negate() };
        }
        return null;
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

pub fn CubeVsCube(pos1: rl.Vector3, rot1: rl.Quaternion, cube1: Cube, pos2: rl.Vector3, rot2: rl.Quaternion, cube2: Cube) ?Manifest {
    // OBB collision using SAT
    const half1 = cube1.length.scale(0.5);
    const half2 = cube2.length.scale(0.5);

    const axes1 = [_]rl.Vector3{
        rl.Vector3.init(1, 0, 0).rotateByQuaternion(rot1),
        rl.Vector3.init(0, 1, 0).rotateByQuaternion(rot1),
        rl.Vector3.init(0, 0, 1).rotateByQuaternion(rot1),
    };
    const axes2 = [_]rl.Vector3{
        rl.Vector3.init(1, 0, 0).rotateByQuaternion(rot2),
        rl.Vector3.init(0, 1, 0).rotateByQuaternion(rot2),
        rl.Vector3.init(0, 0, 1).rotateByQuaternion(rot2),
    };

    var min_overlap: f32 = std.math.floatMax(f32);
    var min_axis = rl.Vector3.zero();

    // Test axes of box1
    for (axes1) |axis| {
        const overlap = testAxis(pos1, half1, axes1, pos2, half2, axes2, axis);
        if (overlap <= 0) return null;
        if (overlap < min_overlap) {
            min_overlap = overlap;
            min_axis = axis;
        }
    }

    // Test axes of box2
    for (axes2) |axis| {
        const overlap = testAxis(pos1, half1, axes1, pos2, half2, axes2, axis);
        if (overlap <= 0) return null;
        if (overlap < min_overlap) {
            min_overlap = overlap;
            min_axis = axis;
        }
    }

    // Test cross product axes
    for (axes1) |a1| {
        for (axes2) |a2| {
            var axis = a1.crossProduct(a2);
            if (axis.dotProduct(axis) < 1e-6) continue; // parallel, skip
            axis = axis.normalize();
            const overlap = testAxis(pos1, half1, axes1, pos2, half2, axes2, axis);
            if (overlap <= 0) return null;
            if (overlap < min_overlap) {
                min_overlap = overlap;
                min_axis = axis;
            }
        }
    }

    // Determine direction using center projections
    const c1 = pos1.dotProduct(min_axis);
    const c2 = pos2.dotProduct(min_axis);
    const final_axis = if (c1 > c2) min_axis.negate() else min_axis;

    return Manifest{
        .penetration = final_axis.scale(min_overlap),
    };
}

fn testAxis(center1: rl.Vector3, half1: rl.Vector3, axes1: [3]rl.Vector3, center2: rl.Vector3, half2: rl.Vector3, axes2: [3]rl.Vector3, axis: rl.Vector3) f32 {
    const p1 = projectOBB(center1, half1, axes1, axis);
    const p2 = projectOBB(center2, half2, axes2, axis);
    const overlap = @min(p1.max, p2.max) - @max(p1.min, p2.min);
    return overlap;
}

const Projection = struct { min: f32, max: f32 };

fn projectOBB(center: rl.Vector3, half: rl.Vector3, axes: [3]rl.Vector3, axis: rl.Vector3) Projection {
    const c = center.dotProduct(axis);
    const e = half.x * @abs(axis.dotProduct(axes[0])) +
        half.y * @abs(axis.dotProduct(axes[1])) +
        half.z * @abs(axis.dotProduct(axes[2]));
    return Projection{
        .min = c - e,
        .max = c + e,
    };
}

pub fn CircleVsCube(sphere_pos: rl.Vector3, sphere: Sphere, cube_pos: rl.Vector3, cube_rot: rl.Quaternion, cube: Cube) ?Manifest {
    // Sphere vs OBB
    const half = cube.length.scale(0.5);
    const axes = [_]rl.Vector3{
        rl.Vector3.init(1, 0, 0).rotateByQuaternion(cube_rot),
        rl.Vector3.init(0, 1, 0).rotateByQuaternion(cube_rot),
        rl.Vector3.init(0, 0, 1).rotateByQuaternion(cube_rot),
    };

    // Find closest point on OBB to sphere center
    var closest = cube_pos;
    const d = sphere_pos.subtract(cube_pos);

    const half_extents = [3]f32{ half.x, half.y, half.z };
    for (0..3) |i| {
        var dist = d.dotProduct(axes[i]);
        const h = half_extents[i];
        if (dist > h) dist = h;
        if (dist < -h) dist = -h;
        closest = closest.add(axes[i].scale(dist));
    }

    const diff = sphere_pos.subtract(closest);
    const dist_sq = diff.dotProduct(diff);
    const radius_sq = sphere.radius * sphere.radius;

    if (dist_sq > radius_sq) return null;

    const dist = @sqrt(dist_sq);
    const penetration = (sphere.radius - dist);
    const normal = if (dist > 1e-6) diff.normalize() else rl.Vector3.init(0, 1, 0); // arbitrary

    return Manifest{
        .penetration = normal.negate().scale(penetration),
    };
}
