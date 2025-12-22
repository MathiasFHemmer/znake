const std = @import("std");
const Scene = @import("./scene_manager/scene.zig").Scene;
const SceneManager = @import("./scene_manager/sceneManager.zig").SceneManager;
const rl = @import("raylib");
const ui = @import("./ui/ui.zig");

pub const MenuScene = struct {
    sceneManager: *SceneManager,
    camera: rl.Camera3D,
    isAllocated: bool = false,
    uiCtx: ui.Context,
    counter: u32,

    pub fn init(allocator: std.mem.Allocator, sceneManager: *SceneManager) !MenuScene {
        _ = allocator;
        return MenuScene{
            .sceneManager = sceneManager,
            .camera = undefined,
            .isAllocated = true,
            .uiCtx = ui.Context.init(),
            .counter = 0,
        };
    }

    pub fn deinit(self: *MenuScene, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }

    pub fn enter(self: *MenuScene) !void {
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
        self.uiCtx.beginDraw(.{
            .data = CustomData
            .layout = .CENTERED,
            .elements = [
                ui.Frame.init(.{
                    .backgroundColor = rl.Color.white,
                    .layout = .TOP_TO_BOTTOM,
                    .onClick = (data) => {

                    }
                    .onHover =...
                })
            ]
        });

        self.uiCtx.beginDraw();
        if (ui.DrawButton(128, 64, rl.Color.white, &self.uiCtx)) {
            self.sceneManager.scheduleSceneSwitch("game") catch {};
        }
        if (ui.DrawButton(128, 64, rl.Color.red, &self.uiCtx)) {
            self.sceneManager.scheduleSceneSwitch("game2") catch {};
        }
        self.uiCtx.endDraw();
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
