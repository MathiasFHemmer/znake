const std = @import("std");
const shapes = @import("../../zhapes/shape.zig");
const Transform = @import("./transform.zig").Transform;
const rlx = @import("../../rayext.zig");
const rl = @import("raylib");

pub const Collider = struct {
    position: rl.Vector3,
    shape: shapes.Shape,

    pub fn init(shape: shapes.Shape) Collider {
        return .{
            .position = .zero(),
            .shape = shape,
        };
    }

    pub fn drawCollider(self: *Collider, transform: *Transform) void {
        switch (self.shape) {
            .cube => |sqr| rlx.drawCubeWiresV(self.position.add(transform.position), sqr.length, transform.rotation, .dark_green),
            .sphere => |sph| rl.drawSphereWires(self.position.add(transform.position), sph.radius, 8, 16, .dark_green),
        }
    }

    // pub fn serialize(self: Collider, writer: *std.io.Writer) !void {
    //     try writer.writeAll(u32, std.mem.asBytes(&self.position.x) .little);
    //     try writer.writeAll(u32, std.mem.asBytes(&self.position.y) .little);
    //     try writer.writeAll(u32, std.mem.asBytes(&self.position.z) .little);
    // }

    // pub fn deserialize(reader: *std.io.Reader, allocator: std.mem.Allocator) !Collider {
    //     _ = allocator;
    //     var x_bytes: [4]u8 = undefined;
    //     _ = try reader.read(&x_bytes);
    //     var y_bytes: [4]u8 = undefined;
    //     _ = try reader.read(&y_bytes);
    //     var z_bytes: [4]u8 = undefined;
    //     _ = try reader.read(&z_bytes);

    //     const position =  rl.Vector3{
    //         .x = @bitCast(std.mem.littleToNative(f32, @as(u32, @bitCast(x_bytes)))),
    //         .y = @bitCast(std.mem.littleToNative(f32, @as(u32, @bitCast(y_bytes)))),
    //         .z = @bitCast(std.mem.littleToNative(f32, @as(u32, @bitCast(z_bytes)))),
    //     };

    //     const key =
    // }
};
