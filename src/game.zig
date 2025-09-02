const std = @import("std");
const math = @import("math/math.zig");
const rl = @import("raylib");
const Scene = @import("scene.zig").Scene;
const ECS = @import("ecs/ecs.zig").ECS;
const AssetManager = @import("asset_manager/asset_manager.zig").AssetManager;
const AssetStore = @import("asset_manager/asset_store.zig").AssetStore;
const Entity = @import("ecs/ecs.zig").Entity;
const Components = @import("ecs/components.zig");
const Snake = @import("ecs/entities/snake.zig");
const WorldEnv = @import("ecs/world.zig");
const World = WorldEnv.World;

const Systems = @import("ecs/systems.zig");

pub const GameScene = struct {
    allocator: std.mem.Allocator,
    camera: *rl.Camera3D,
    snake: Entity,
    world: World,
    worldTarget: rl.RenderTexture2D,

    pub fn init(camera: *rl.Camera3D, allocator: std.mem.Allocator) !GameScene {
        rl.disableCursor();

        var world = try World.init(allocator);
        try Snake.generateDefaults(allocator, &world.assetManager);

        const snake = try Snake.create(&world, .init(1, 0, 1));

        return GameScene{
            .camera = camera,
            .allocator = allocator,
            .snake = snake,
            .worldTarget = try rl.loadRenderTexture(800, 450),
            .world = world,
        };
    }

    pub fn deinit(self: *GameScene) void {
        self.world.deinit();
    }

    pub fn start(self: *GameScene) !void {
        _ = self;
    }
    pub fn fixedUpdate(self: *GameScene, dt: f32) void {
        Systems.playerMove(&self.world, dt);
    }
    pub fn update(self: *GameScene) void {
        self.camera.update(.third_person);
        const dt = rl.getFrameTime();

        Systems.playerControllerUpdate(&self.world, self.snake, dt);
    }
    pub fn render(self: *GameScene, alphaDt: f32) !void {
        rl.beginTextureMode(self.worldTarget);
        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(self.camera.*);

        Systems.drawMeshSystem(&self.world, alphaDt);

        rl.endMode3D();
        rl.endTextureMode();
        // rl.beginShaderMode(self.snake.fowShader);
        rl.drawTextureRec(self.worldTarget.texture, .init(0, 0, 800, -450), .init(0, 0), .white);
        rl.endShaderMode();
    }
    pub fn renderUI(self: *GameScene) !void {
        _ = self;
    }
    pub fn exit(self: *GameScene) void {
        _ = self;
    }
    pub fn asScene(self: *GameScene) Scene {
        return Scene.init(self);
    }
};
