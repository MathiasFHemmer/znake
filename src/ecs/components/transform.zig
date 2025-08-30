const rl = @import("raylib");

pub const Transform = struct {
    position: rl.Vector3,
    rotation: rl.Quaternion,
    scale: rl.Vector3,

    // Previous fixedUpdate frame values for interpolation
    oldPosition: rl.Vector3,
    oldRotation: rl.Quaternion,
    oldScale: rl.Vector3,

    // transformations
    forward: rl.Vector3,

    pub fn init() Transform {
        return Transform{
            .position = .init(0, 0, 0),
            .rotation = .identity(),
            .scale = .init(1, 2, 3),
            .oldPosition = .init(0, 0, 0),
            .oldRotation = .identity(),
            .oldScale = .one(),
            .forward = .init(0, 0, 1),
        };
    }
};
