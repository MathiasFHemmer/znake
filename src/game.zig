const std = @import("std");
const rl = @import("raylib");
const Scene = @import("scene.zig").Scene;
const ECS = @import("ecs/ecs.zig").ECS;
const AssetManager = @import("ecs/asset_manager.zig");
const Entity = @import("ecs/ecs.zig").Entity;
const Components = @import("ecs/components.zig");

const ShaderStore = AssetManager.AssetStore(rl.Shader);

const Rotation = struct { a: f32 };

const WorldComponents = struct {
    Transform: Components.Transform,
    Rigidbody: Components.Rigidbody,
    Rotation: Rotation,
    MeshRenderer: Components.MeshRenderer,
};

const World = ECS(WorldComponents);

const DEG2RAD: f32 = std.math.pi / 180.0;
const RAD2DEG: f32 = 1.0 / DEG2RAD;

pub fn CreateSnakeMesh(allocator: std.mem.Allocator, store: *ShaderStore) !Components.MeshRenderer {
    const half = 0.5 * 1;
    const vertices = try allocator.dupe(f32, &[_]f32{
        -half, 0, -half,
        half,  0, -half,
        -half, 0, half,
        half,  0, half,
    });

    const normals = try allocator.dupe(f32, &[_]f32{
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
    });

    const indices = try allocator.dupe(c_ushort, &[_]c_ushort{
        2, 1, 0,
        2, 3, 1,
    });

    var mesh = rl.Mesh{
        .vertexCount = 4,
        .triangleCount = 2,
        .vertices = vertices.ptr,
        .texcoords = null,
        .texcoords2 = null,
        .normals = normals.ptr,
        .tangents = null,
        .colors = null,
        .indices = indices.ptr,
        .animVertices = null,
        .animNormals = null,
        .boneIds = null,
        .boneWeights = null,
        .boneMatrices = null,
        .boneCount = 0,
        .vaoId = 0,
        .vboId = null,
    };

    defer allocator.free(vertices);
    defer allocator.free(normals);
    defer allocator.free(indices);

    rl.uploadMesh(&mesh, false);
    return try Components.MeshRenderer.init(mesh, store);
}

pub const GameScene = struct {
    allocator: std.mem.Allocator,
    camera: *rl.Camera3D,
    camPosition: rl.Vector3,
    snake: Entity,
    worldTarget: rl.RenderTexture2D,
    world: World,
    shaders: ShaderStore,

    snakeMesh: Components.MeshRenderer,

    pub fn init(camera: *rl.Camera3D, allocator: std.mem.Allocator) !GameScene {
        var world = World.init(allocator);
        var store = ShaderStore.init(allocator, &AssetManager.rlLoadShaderWrapper, &AssetManager.rlUnloadShaderWrapper);
        rl.disableCursor();
        World.printRegistry();
        const snakeMesh = try CreateSnakeMesh(allocator, &store);

        const snake = world.createEntity();
        world.addComponent(snake, Components.Transform.init());
        world.addComponent(snake, Components.Rigidbody.init());
        world.addComponent(snake, Rotation{ .a = 0 });
        world.addComponent(snake, snakeMesh);

        store.preload("shaders/snek") catch |err| {
            std.debug.print("Failed to preload shader: {any}\n", .{err});
        };
        return GameScene{
            .camera = camera,
            .camPosition = rl.Vector3.zero(),
            .allocator = allocator,
            .snake = snake,
            .worldTarget = try rl.loadRenderTexture(800, 450),
            .world = world,
            .snakeMesh = snakeMesh,
            .shaders = store,
        };
    }

    pub fn deinit(self: *GameScene) void {
        self.world.deinit();
        self.snakeMesh.deinit(self.allocator, &self.shaders);
        self.shaders.deinit();
    }

    pub fn start(self: *GameScene) !void {
        self.camPosition = self.camera.position;
    }
    pub fn fixedUpdate(self: *GameScene, dt: f32) void {
        var query = self.world.query(struct { transform: Components.Transform, rigidbody: Components.Rigidbody, rotation: Rotation }).sets;
        for (query.transform.dense.items, query.transform.entities.items) |*t, entity| {
            const vel = query.rigidbody.getUnsafe(entity).velocity;
            const rot = query.rotation.getUnsafe(entity);

            t.oldPosition = t.position;
            t.oldRotation = t.rotation;
            t.oldScale = t.scale;

            var pos = &t.position;

            t.rotation = rl.Quaternion.fromAxisAngle(.init(0, 1, 0), rot.a).normalize();
            const dir = t.forward.rotateByQuaternion(t.rotation).multiply(vel).scale(dt);

            pos.x += dir.x;
            pos.y += dir.y;
            pos.z += dir.z;
        }
    }
    pub fn update(self: *GameScene) void {
        self.camera.update(.third_person);
        const dt = rl.getFrameTime();
        const rotation = self.world.getComponent(self.snake, Rotation);
        const rb = self.world.getComponent(self.snake, Components.Rigidbody);

        if (rl.isMouseButtonPressed(.left)) {
            self.world.removeEntity(self.snake);
        }
        if (rotation) |rot| {
            if (rl.isKeyDown(rl.KeyboardKey.j)) {
                rot.a += 100 * DEG2RAD * dt;
            }
            if (rl.isKeyDown(rl.KeyboardKey.l)) {
                rot.a -= 100 * DEG2RAD * dt;
            }

            if (rb) |_rb| {
                var speed: f32 = 0;
                if (rl.isKeyDown(rl.KeyboardKey.i)) {
                    speed = 10;
                }
                if (rl.isKeyDown(rl.KeyboardKey.k)) {
                    speed = -10;
                }

                _rb.velocity.x = speed;
                _rb.velocity.y = 0;
                _rb.velocity.z = speed;
            }
        }
    }
    pub fn render(self: *GameScene, alphaDt: f32) !void {
        rl.beginTextureMode(self.worldTarget);
        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(self.camera.*);

        var query = self.world.query(struct { meshRender: Components.MeshRenderer, transform: Components.Transform }).sets;
        for (query.meshRender.dense.items, query.meshRender.entities.items) |*mesh, entity| {
            const trans = query.transform.getUnsafe(entity);

            // Extrapolate position
            const deltaPos = trans.position.subtract(trans.oldPosition);
            const i_pos = trans.position.add(deltaPos.scale(alphaDt));

            // Extrapolate rotation
            const rot = trans.rotation.multiply(trans.oldRotation.invert());
            var ang: f32 = undefined;
            var axis: rl.Vector3 = undefined;
            rot.toAxisAngle(&axis, &ang);
            const i_quaternion = trans.rotation.multiply(rl.Quaternion.fromAxisAngle(axis, ang));
            _ = i_quaternion;
            mesh.drawMesh(i_pos, trans.scale, trans.oldRotation.nlerp(trans.rotation, alphaDt));
        }

        rl.endMode3D();
        rl.endTextureMode();

        // rl.beginShaderMode(self.snake.fowShader);
        rl.drawTextureRec(
            self.worldTarget.texture,
            rl.Rectangle.init(0, 0, 800, -450), // flip Y
            rl.Vector2.init(0, 0),
            rl.Color.white,
        );
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
