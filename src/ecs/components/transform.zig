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

    pub fn worldForward(self: *Transform) rl.Vector3 {
        return self.forward.rotateByQuaternion(self.rotation);
    }

    pub fn init(position: rl.Vector3) Transform {
        return Transform{
            .position = position,
            .rotation = .identity(),
            .scale = .one(),
            .oldPosition = position,
            .oldRotation = .identity(),
            .oldScale = .one(),
            .forward = .init(0, 0, 1),
        };
    }
};
