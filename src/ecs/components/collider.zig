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
};
