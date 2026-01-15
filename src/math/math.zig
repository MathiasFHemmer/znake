const std = @import("std");
const rl = @import("raylib");

pub const DEG2RAD: f32 = std.math.pi / 180.0;
pub const RAD2DEG: f32 = 1.0 / DEG2RAD;

pub const Vector2 = struct {
    const Self = @This();

    x: f32 = 0,
    y: f32 = 0,

    pub const empty: Self = .{ .x = 0, .y = 0 };

    pub fn init(x: f32, y: f32) Self {
        return .{
            .x = x,
            .y = y,
        };
    }

    pub fn copy(source: Vector2) Self {
        return .{
            .x = source.x,
            .y = source.y,
        };
    }

    pub fn add(self: *Self, source: Vector2) Self {
        return .{
            .x = self.x + source.x,
            .y = self.y + source.y,
        };
    }

    // RAYLIB SPECIFIC CROSS COMPATIBILITY
    pub fn fromRLVector2(source: rl.Vector2) Self {
        return Self{ .x = source.x, .y = source.y };
    }
};
