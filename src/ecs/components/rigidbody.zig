const rl = @import("raylib");
const Transform = @import("transform.zig").Transform;

pub const Rigidbody = struct {
    velocity: rl.Vector3,

    pub fn init() Rigidbody {
        return Rigidbody{
            .velocity = .init(0, 0, 0),
        };
    }
};
