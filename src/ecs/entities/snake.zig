const std = @import("std");
const rl = @import("raylib");
const WorldEnv = @import("../world.zig");
const AssetManager = @import("../../asset_manager/asset_manager.zig").AssetManager;
const Components = @import("../components.zig");
const Entity = @import("zecs").Entity;

pub const SNAKE_MESH_KEY = "snake_default";
pub const SNAKE_SHADER_KEY = "default";

var INDICES = [6]c_ushort{
    2, 1, 0,
    2, 3, 1,
};
var NORMALS = [12]f32{
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
    0, 1, 0,
};
const half = 0.5 * 1;
var VERTICES = [12]f32{
    -half, 0, -half,
    half,  0, -half,
    -half, 0, half,
    half,  0, half,
};

pub fn create(world: *WorldEnv.World, position: rl.Vector3) !Entity {
    const entity = world.createEntity();

    // const mesh = world.assetManager.meshStore.get(SNAKE_MESH_KEY) catch @panic("Default snake mesh not found, did you call `generateDefaults`?");
    // const shader = world.assetManager.shaderStore.get(SNAKE_SHADER_KEY) catch @panic("Default shader not found, did you call `generateDefaults`?");

    world.addComponent(entity, Components.Transform.init(position));
    world.addComponent(entity, Components.Rotation.init(0));
    world.addComponent(entity, Components.Rigidbody.init(10));
    world.addComponent(entity, try Components.MeshRenderer.init(SNAKE_MESH_KEY, SNAKE_SHADER_KEY));
    world.addComponent(entity, Components.Collider.init(.{ .sphere = .unit() }));

    return entity;
}

fn createMesh(allocator: std.mem.Allocator) !rl.Mesh {
    _ = allocator;
    return rl.Mesh{
        .vertexCount = 4,
        .triangleCount = 2,
        .vertices = &VERTICES,
        .texcoords = null,
        .texcoords2 = null,
        .normals = &NORMALS,
        .tangents = null,
        .colors = null,
        .indices = &INDICES,
        .animVertices = null,
        .animNormals = null,
        .boneIds = null,
        .boneWeights = null,
        .boneMatrices = null,
        .boneCount = 0,
        .vaoId = 0,
        .vboId = null,
    };
}

pub fn generateDefaults(allocator: std.mem.Allocator, assetManager: *AssetManager) !void {
    const mesh = try createMesh(allocator);
    _ = try assetManager.meshStore.add(SNAKE_MESH_KEY, mesh);
}
