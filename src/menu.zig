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
    pub fn renderUI(self: *MenuScene) !void {
        self.ui.syncScreenSize(@floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight()));

        self.ui.beginLayout();
        self.ui.openScope(ui.Box.init(.{
            .layout = .LeftToRight,
            .sizing = .{
                .width = .{ .fit = .{ .min = if (self.do) 350 else 650, .max = if (self.do) 350 else 650 } },
                .height = .{ .fit = .{ .min = if (self.do) 350 else 650, .max = if (self.do) 350 else 650 } },
            },
            .padding = .{ .bottom = 4, .left = 4, .right = 5, .top = 10 },
            .gap = 2,
            .color = rl.Color.dark_purple,
        }));
        {
            self.ui.openScope(ui.Box.init(.{
                .sizing = .{
                    .width = .{ .fixed = .{ .value = 200 } },
                    .height = .{ .fixed = .{ .value = 200 } },
                },
                .color = rl.Color.blue,
            }));
            self.ui.closeScope();

            if (self.do) {}
            self.ui.openScope(ui.Box.init(.{
                .sizing = .{ .width = .{ .grow = .{
                    .value = 0,
                } }, .height = .{ .fit = .{ .value = 100 } } },
                .color = rl.Color.red,
            }));
            self.ui.closeScope();
            if (self.do2) {
                self.ui.openScope(ui.Box.init(.{
                    .sizing = .{ .width = .{ .fixed = .{ .value = 250 } }, .height = .{ .fixed = .{ .value = 250 } } },
                    .color = rl.Color.green,
                }));
                self.ui.closeScope();
            }

            for (0..self.counter) |index| {
                self.ui.openScope(ui.Box.init(.{
                    .layout = .TopToBottom,
                    .sizing = .{ .width = .{ .fixed = .{ .value = 50 } }, .height = .{ .fixed = .{ .value = 50 } } },
                    .color = rl.Color.gold.fade(@as(f32, @floatFromInt(20 - index)) / 20.0),
                }));
                self.ui.closeScope();
            }
        }
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
