const Scene = @import("scene.zig").Scene;
const rl = @import("raylib");

pub const MenuScene = struct {
    pub fn init() MenuScene {
        return MenuScene{};
    }

    pub fn start(self: *MenuScene) !void {
        _ = self;
    }
    pub fn fixedUpdate(self: *MenuScene, dt: f32) void {
        _ = self;
        _ = dt;
    }
    pub fn update(self: *MenuScene) void {
        _ = self;
    }
    pub fn render(self: *MenuScene, alphaDt: f32) !void {
        _ = self;
        _ = alphaDt;
    }
    pub fn renderUI(self: *MenuScene) !void {
        _ = self;
        rl.drawText("PRESS SPACE TO PLAY", 100, 100, 20, .white);
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
