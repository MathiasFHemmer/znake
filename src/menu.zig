const Scene = @import("scene.zig").Scene;
const rl = @import("raylib");

pub const MenuScene = struct {
    camera: *rl.Camera3D,

    pub fn init(camera: *rl.Camera3D) MenuScene {
        return MenuScene{
            .camera = camera,
        };
    }

    pub fn start(self: *MenuScene) !void {
        _ = self;
    }
    pub fn fixedUpdate(self: *MenuScene, dt: f32) void {
        _ = self;
        _ = dt;
    }
    pub fn update(self: *MenuScene) void {
        self.camera.update(.orbital);
    }
    pub fn render(self: *MenuScene, alphaDt: f32) !void {
        _ = self;
        _ = alphaDt;
    }
    pub fn renderUI(self: *MenuScene) !void {
        _ = self;
        const posY = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0;
        const posX = (@as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0) - (@as(f32, @floatFromInt(rl.measureText("GET IN LOSER, WE GOT APPLES TO EAT!", 20))) / 2.0);
        rl.drawText("GET IN LOSER, WE GOT APPLES TO EAT!", @intFromFloat(posX), @intFromFloat(posY), 20, .white);
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
