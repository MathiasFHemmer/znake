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
    ui: ui.Canvas,
    counter: u32,
    customData: CustomData,

    do: bool = false,
    do2: bool = false,

    pub fn init(allocator: std.mem.Allocator, sceneManager: *SceneManager) !MenuScene {
        return MenuScene{
            .sceneManager = sceneManager,
            .camera = undefined,
            .isAllocated = true,
            .ui = ui.Canvas.init(allocator),
            .counter = 0,
            .customData = CustomData{ .sceneManager = sceneManager },
        };
    }

    pub fn deinit(self: *MenuScene, allocator: std.mem.Allocator) void {
        _ = allocator;
        _ = self;
    }

    pub fn enter(self: *MenuScene) !void {
        _ = self;
    }
    pub fn fixedUpdate(self: *MenuScene, dt: f32) void {
        _ = self;
        _ = dt;
    }
    pub fn update(self: *MenuScene) void {
        // _ = self;

        self.do = rl.isKeyDown(.s);
        self.do2 = rl.isKeyDown(.d);
        if (rl.isKeyReleased(.space)) {
            self.counter += 1;
        }
        if (rl.isKeyReleased(.x)) {
            self.counter -= 1;
        }
    }
    pub fn render(self: *MenuScene, alphaDt: f32) !void {
        _ = self;
        _ = alphaDt;
        rl.clearBackground(rl.Color.black);
    }

    pub fn clickHandler(data: ?*anyopaque) void {
        const scene = @as(*MenuScene, @ptrCast(@alignCast(data.?)));
        scene.sceneManager.scheduleSceneSwitch("game") catch unreachable;
    }

    pub fn exitHandler(data: ?*anyopaque) void {
        const scene = @as(*MenuScene, @ptrCast(@alignCast(data.?)));
        scene.sceneManager.setExit();
    }

    pub fn renderUI(self: *MenuScene) !void {
        self.ui.syncScreenSize(@floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight()));
        self.ui.syncMouseState(.{ .poistion = .fromRLVector2(rl.getMousePosition()), .pressed = rl.isMouseButtonDown(.left), .released = rl.isMouseButtonReleased(.left) });
        self.ui.beginLayout();
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .grow = .{ .value = 0 } },
                .width = .{ .grow = .{ .value = 0 } },
            },
        }));
        self.ui.closeScope();

        self.ui.openScope(ui.Box.init(.{
            .layout = .TopToBottom,
            .sizing = .{
                .height = .{ .grow = .{ .value = 0 } },
                .width = .{ .grow = .{ .value = 0 } },
            },
            .gap = 8,
        }));
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .grow = .{ .value = 0 } },
                .width = .{ .grow = .{ .value = 0 } },
            },
        }));
        self.ui.closeScope();
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .fixed = .{ .value = 60 } },
                .width = .{ .grow = .{ .value = 100 } },
            },
            .color = rl.Color.gold,
            .onClick = clickHandler,
            .onClickPayload = self,
        }));
        self.ui.closeScope();
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .fixed = .{ .value = 60 } },
                .width = .{ .grow = .{ .value = 100 } },
            },
            .color = rl.Color.gold,
            .onClick = exitHandler,
            .onClickPayload = self,
        }));
        self.ui.closeScope();
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .grow = .{ .value = 0 } },
                .width = .{ .grow = .{ .value = 0 } },
            },
        }));
        self.ui.closeScope();
        self.ui.closeScope();
        self.ui.openScope(ui.Box.init(.{
            .sizing = .{
                .height = .{ .grow = .{ .value = 0 } },
                .width = .{ .grow = .{ .value = 0 } },
            },
        }));
        self.ui.closeScope();

        self.ui.endLayout();
    }
    pub fn exit(self: *MenuScene) void {
        _ = self;
    }

    pub fn asScene(self: *MenuScene) Scene {
        return Scene.init(self);
    }
};
