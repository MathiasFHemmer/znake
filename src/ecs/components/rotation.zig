pub const Rotation = struct {
    a: f32,

    pub fn init(angle: f32) Rotation {
        return Rotation{ .a = angle };
    }
};
