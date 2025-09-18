const rl = @import("raylib");

pub const Input = struct {
    movement: rl.Vector2,
    slow: bool,

    pub fn init() Input {
        return .{ .movement = .zero(), .slow = false };
    }
};
