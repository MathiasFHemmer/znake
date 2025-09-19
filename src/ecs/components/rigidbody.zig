const rl = @import("raylib");
const Transform = @import("transform.zig").Transform;

pub const Rigidbody = struct {
    velocity: rl.Vector3,
    mass: f32,

    pub fn init(mass: f32) Rigidbody {
        return Rigidbody{
            .mass = mass,
            .velocity = .init(0, 0, 0),
        };
    }
};
