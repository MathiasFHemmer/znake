const std = @import("std");
const math = @import("math/math.zig");
const rl = @import("raylib");
const Scene = @import("scene.zig").Scene;
const ECS = @import("ecs/ecs.zig").ECS;
const AssetManager = @import("asset_manager/asset_manager.zig").AssetManager;
const AssetStore = @import("asset_manager/asset_store.zig").AssetStore;
const Entity = @import("ecs/ecs.zig").Entity;
const Components = @import("ecs/components.zig");
const Apple = @import("ecs/entities/apple.zig");
const Snake = @import("ecs/entities/snake.zig");
const Spike = @import("ecs/entities/spike.zig");
const WorldEnv = @import("ecs/world.zig");
const World = WorldEnv.World;
const Input = @import("input.zig").Input;

const Systems = @import("ecs/systems.zig");

pub const GameScene = struct {
    allocator: std.mem.Allocator,
    camera: *rl.Camera3D,
    snake: Entity,
    world: World,
    worldTarget: rl.RenderTexture2D,

    pub fn init(camera: *rl.Camera3D, allocator: std.mem.Allocator) !GameScene {
        rl.disableCursor();
        camera.up = .init(0, 0, 1);

        var world = try World.init(allocator);
        try Snake.generateDefaults(allocator, &world.assetManager);
        try Apple.generateDefaults(allocator, &world.assetManager);
        try Spike.generateDefaults(allocator, &world.assetManager);
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
        Systems.checkAppleEat(self.snake, &self.world);
        Systems.playerMove(&self.world, self.snake, dt);
    }
    pub fn update(self: *GameScene) void {
        self.camera.update(.orbital);
        const dt = rl.getFrameTime();

        Systems.gatherInput(&self.world);
        Systems.playerControllerUpdate(&self.world, self.snake, dt);
        Systems.checkSpawnApple(&self.world, dt) catch @panic("A!");
        Systems.spikeSpawner(&self.world, dt) catch @panic("A!");

        // const t = self.world.getComponent(self.snake, Components.Transform).?;
        // const cameraPos = (t.position.scale(dt)).add(t.position.scale(1 - dt));
        // self.camera.target = cameraPos;
        // self.camera.position = cameraPos.add(.init(0, 10, 0));

        self.camera.target = self.world.getComponent(self.snake, Components.Transform).?.position;
        self.camera.position = self.world.getComponent(self.snake, Components.Transform).?.position.add(.init(0, 10, 0));
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
        // _ = self;
        rl.drawText(rl.textFormat("Score: %1i", .{self.world.state.applesEaten}), 0, 50, 14, .white);
    }
    pub fn exit(self: *GameScene) void {
        _ = self;
    }
    pub fn asScene(self: *GameScene) Scene {
        return Scene.init(self);
    }
};
