const std = @import("std");
const math = @import("math/math.zig");
const rl = @import("raylib");
const logger = std.log.scoped(.Game);
const Scene = @import("./scene_manager/scene.zig").Scene;
const SceneManager = @import("./scene_manager/sceneManager.zig").SceneManager;
const AssetManager = @import("asset_manager/asset_manager.zig").AssetManager;
const AssetStore = @import("asset_manager/asset_store.zig").AssetStore;
const Entity = @import("zecs").Entity;
const Components = @import("ecs/components.zig");
const Apple = @import("ecs/entities/apple.zig");
const Snake = @import("ecs/entities/snake.zig");
const Spike = @import("ecs/entities/spike.zig");
const WorldEnv = @import("ecs/world.zig");
const World = WorldEnv.World;
const Input = @import("input.zig").Input;
const ui = @import("./ui/ui.zig");
const Systems = @import("ecs/systems.zig");

var saveCD: f32 = 0;

pub const GameScene = struct {
    const Self = @This();

    sceneManager: *SceneManager,
    ui: ui.UI,
    showMenu: bool,

    snake: Entity,
    world: World,

    camera: rl.Camera3D,
    mainTexture: rl.RenderTexture2D,
    allocator: std.mem.Allocator,

    pub const empty = Self{
        .snake = 0,
        .world = {},
        .camera = undefined,
        .mainTexture = {},
        .allocator = undefined,
    };

    pub fn init(allocator: std.mem.Allocator, sceneManager: *SceneManager) !Self {
        //rl.disableCursor();

        var world = try World.init(allocator);
        const snake = try Snake.create(&world, .init(1, 0, 1));
        logger.debug("Player created: {d}", .{snake});

        return Self{
            .sceneManager = sceneManager,
            .snake = snake,
            .mainTexture = try rl.loadRenderTexture(1920, 1080),
            .world = world,
            .ui = ui.UI.init(allocator),
            .showMenu = false,
            .camera = rl.Camera3D{
                .position = rl.Vector3{ .x = 10, .y = 10, .z = 10 },
                .target = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
                .up = rl.Vector3{ .x = 0, .y = 0, .z = 1 },
                .fovy = 45,
                .projection = rl.CameraProjection.perspective,
            },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GameScene, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.world.deinit();
        self.ui.deinit();
    }

    pub fn enter(self: *GameScene) !void {
        _ = self;
    }

    pub fn fixedUpdate(self: *GameScene, dt: f32) void {
        if (self.showMenu) return;

        Systems.playerMove(&self.world, self.snake, dt);
        Systems.checkCollisions(&self.world);
        Systems.checkAppleEat(self.snake, &self.world);
    }
    pub fn update(self: *GameScene) void {
        if (rl.isKeyPressed(rl.KeyboardKey.escape)) {
            self.showMenu = !self.showMenu;
        }

        if (self.showMenu) return;

        const dt = rl.getFrameTime();

        Systems.gatherInput(&self.world);
        Systems.playerControllerUpdate(&self.world, self.snake, dt);
        Systems.checkSpawnApple(&self.world, dt) catch @panic("A!");
        Systems.spikeSpawner(&self.world, dt) catch @panic("A!");

        if (rl.isKeyDown(.q) and saveCD <= 0) {
            saveCD = 1;
            const file: ?std.fs.File = std.fs.cwd().createFile("entity", .{ .read = true }) catch null;
            const version = std.SemanticVersion.parse("1.2.3") catch unreachable;
            if (file) |f| {
                logger.info("Saving world data...", .{});
                self.world.printRegistry();
                //var buffer: [4096]u8 = undefined;
                var writer = f.writer(&.{});
                self.world.serialize(&writer.interface, version) catch unreachable;
                writer.end() catch unreachable;
                logger.info("Save complete!", .{});
            }
        }

        if (rl.isKeyDown(.e) and saveCD <= 0) {
            saveCD = 1;
            const file: ?std.fs.File = std.fs.cwd().openFile("entity", .{}) catch null;
            const version = std.SemanticVersion.parse("1.0.0") catch unreachable;
            if (file) |f| {
                const stats = f.stat();
                logger.debug("Loading save file...", .{});
                logger.debug("Save File stats: {any}", .{stats});

                var buffer: [4096]u8 = undefined;
                var reader = f.reader(&buffer);

                logger.debug("Unloading current world data...", .{});
                self.world.deinit();

                logger.debug("Initializing default world data...", .{});
                self.world = World.init(self.allocator) catch unreachable;
                logger.debug("World data initialization complete!", .{});
                self.world.printRegistry();

                logger.debug("Deserializing save file...", .{});
                _ = self.world.deserialize(&reader.interface, version) catch unreachable;
                self.world.state.applesAlive = 1;
                self.world.printRegistry();
            }
        }
        if (saveCD > 0) {
            saveCD -= dt;
        }

        self.camera.target = self.world.getComponent(self.snake, Components.Transform).?.position;
        self.camera.position = self.world.getComponent(self.snake, Components.Transform).?.position.add(.init(0, 10, 0));
    }
    pub fn render(self: *GameScene, alphaDt: f32) !void {
        rl.beginTextureMode(self.mainTexture);
        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(self.camera);

        Systems.drawMeshSystem(&self.world, alphaDt);

        rl.endMode3D();
        rl.endTextureMode();
        // rl.beginShaderMode(self.snake.fowShader);
        rl.drawTextureRec(self.mainTexture.texture, .init(0, 0, 1920, -1080), .init(0, 0), .white);
        rl.endShaderMode();

        drawWorldAxes(self.camera);
    }
    pub fn renderUI(self: *GameScene) !void {
        // _ = self;
        rl.drawText(rl.textFormat("Score: %1i", .{self.world.state.applesEaten}), 0, 50, 14, .white);

        const menuUi = struct {
            fn draw(canvas: *ui.UI, scene: *GameScene) void {
                canvas.beginLayout(.TOP_TO_BOTTOM, .{ .margin = .{ .relative = .init(0.5, 0.5) } });
                defer canvas.endLayout();

                if (canvas.button("Quit", .{})) {
                    scene.sceneManager.setExit();
                }
            }
        }.draw;
        if (self.showMenu) {
            self.ui.run(self, menuUi);
        }
    }
    pub fn exit(self: *GameScene) void {
        _ = self;
    }
    pub fn asScene(self: *GameScene) Scene {
        return Scene.init(self);
    }

    pub fn drawWorldAxes(camera: rl.Camera3D) void {
        const axisLength: f32 = 10.0;
        const origin = rl.Vector3.zero();
        // std.time.sleep(1000 * 1000 * 100);
        rl.beginMode3D(camera);

        rl.drawLine3D(origin, rl.Vector3{ .x = axisLength, .y = 0, .z = 0 }, rl.Color.red);
        rl.drawLine3D(origin, rl.Vector3{ .x = 0, .y = axisLength, .z = 0 }, rl.Color.green);
        rl.drawLine3D(origin, rl.Vector3{ .x = 0, .y = 0, .z = axisLength }, rl.Color.blue);

        rl.endMode3D();
        rl.drawFPS(10, 10);
        drawAxisLabel(rl.Vector3{ .x = axisLength + 0.5, .y = 0, .z = 0 }, "X", rl.Color.red, camera);
        drawAxisLabel(rl.Vector3{ .x = 0, .y = axisLength + 0.5, .z = 0 }, "Y", rl.Color.green, camera);
        drawAxisLabel(rl.Vector3{ .x = 0, .y = 0, .z = axisLength + 0.5 }, "Z", rl.Color.blue, camera);
    }

    fn drawAxisLabel(position: rl.Vector3, text: [:0]const u8, color: rl.Color, camera: rl.Camera3D) void {
        const screenPos = rl.getWorldToScreen(position, camera);
        rl.drawText(text, @intFromFloat(screenPos.x), @intFromFloat(screenPos.y), 20, color);
    }
};
