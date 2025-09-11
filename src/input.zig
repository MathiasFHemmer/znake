const rl = @import("raylib");

pub const Input = struct {
    movement: rl.Vector2,

    pub fn init() Input {
        return .{ .movement = .zero() };
    }
};
