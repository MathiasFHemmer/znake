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
    uiCtx: ui.Context,
    counter: u32,
    customData: CustomData,

    pub fn init(allocator: std.mem.Allocator, sceneManager: *SceneManager) !MenuScene {
        _ = allocator;
        return MenuScene{
            .sceneManager = sceneManager,
            .camera = undefined,
            .isAllocated = true,
            .uiCtx = ui.Context.init(),
            .counter = 0,
            .customData = CustomData{ .sceneManager = sceneManager },
        };
    }

    pub fn deinit(self: *MenuScene, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.uiCtx.deinit();
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
        const ctx = &self.uiCtx;
        ctx.clear();

        // Build UI
        try ctx.beginElement(.{
            .id = "root",
            .backgroundColor = rl.Color{ .r = 50, .g = 50, .b = 50, .a = 255 },
            .layout = .TOP_TO_BOTTOM,
            .dimension = rl.Vector2{ .x = 400, .y = 600 },
            .position = rl.Vector2{ .x = 100, .y = 100 },
        });

        try ctx.beginElement(.{
            .id = "title",
            .backgroundColor = rl.Color{ .r = 100, .g = 100, .b = 200, .a = 255 },
            .dimension = rl.Vector2{ .x = 300, .y = 100 },
        });
        ctx.endElement();

        try ctx.beginElement(.{
            .id = "buttons",
            .backgroundColor = rl.Color{ .r = 80, .g = 80, .b = 80, .a = 255 },
            .layout = .TOP_TO_BOTTOM,
            .dimension = rl.Vector2{ .x = 400, .y = 200 },
        });

        try ctx.beginElement(.{
            .id = "start_button",
            .backgroundColor = rl.Color{ .r = 0, .g = 255, .b = 0, .a = 255 },
            .dimension = rl.Vector2{ .x = 200, .y = 50 },
        });
        ctx.endElement();

        try ctx.beginElement(.{
            .id = "exit_button",
            .backgroundColor = rl.Color{ .r = 255, .g = 0, .b = 0, .a = 255 },
            .dimension = rl.Vector2{ .x = 200, .y = 50 },
        });
        ctx.endElement();

        ctx.endElement();
        ctx.endElement();
        ctx.render();
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
