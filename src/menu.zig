const std = @import("std");
const Scene = @import("./scene_manager/scene.zig").Scene;
const SceneManager = @import("./scene_manager/sceneManager.zig").SceneManager;
const rl = @import("raylib");
const ui = @import("./ui/ui.zig");
const logger = @import("std").log.scoped(.MENU);

pub const CustomData = struct {
    sceneManager: *SceneManager,
};

pub const MenuScene = struct {
    sceneManager: *SceneManager,
    camera: rl.Camera3D,
    isAllocated: bool = false,
    ui: ui.UI,
    counter: u32,
    customData: CustomData,

    pub fn init(allocator: std.mem.Allocator, sceneManager: *SceneManager) !MenuScene {
        return MenuScene{
            .sceneManager = sceneManager,
            .camera = undefined,
            .isAllocated = true,
            .ui = ui.UI.init(allocator),
            .counter = 0,
            .customData = CustomData{ .sceneManager = sceneManager },
        };
    }

    pub fn deinit(self: *MenuScene, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.ui.deinit();
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
        const menuUi = struct {
            fn draw(canvas: *ui.UI, scene: *MenuScene) void {
                canvas.beginLayout(.TOP_TO_BOTTOM, .{ .margin = .{ .relative = .init(0.5, 0.5) } });
                defer canvas.endLayout();

                if (canvas.button("Play", .{})) {
                    scene.sceneManager.scheduleSceneSwitch("game") catch unreachable;
                }
                if (canvas.button("Quit", .{})) {
                    scene.sceneManager.setExit();
                }
            }
        }.draw;

        self.ui.run(self, menuUi);
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
