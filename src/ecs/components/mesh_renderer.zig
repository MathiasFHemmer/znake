const std = @import("std");
const rl = @import("raylib");
const Serializer = @import("zerializer").Serializer;
const Deserializer = @import("zerializer").Deserializer;
const AssetManager = @import("../../asset_manager/asset_manager.zig").AssetManager;
const AssetHandle = @import("asset_handle.zig").AssetHandle;
const Transform = @import("transform.zig").Transform;

pub const MeshRenderer = struct {
    tint: rl.Color,
    material: rl.Material,
    meshHandle: AssetHandle,
    shaderHandle: AssetHandle,

    pub fn serialize(self: MeshRenderer, writer: *std.io.Writer) !void {
        try Serializer.serialize(rl.Color, self.tint, writer);
        try Serializer.serialize(AssetHandle, self.meshHandle, writer);
        try Serializer.serialize(AssetHandle, self.shaderHandle, writer);
    }

    pub fn deserialize(reader: *std.io.Reader, allocator: std.mem.Allocator) !MeshRenderer {
        const color = try Deserializer.deserialize(rl.Color, reader, allocator);
        const meshHandle = try Deserializer.deserialize(AssetHandle, reader, allocator);
        const shaderHanle = try Deserializer.deserialize(AssetHandle, reader, allocator);
        return MeshRenderer{
            .tint = color,
            .material = try rl.loadMaterialDefault(),
            .meshHandle = meshHandle,
            .shaderHandle = shaderHanle,
        };
    }

    pub fn init(meshHandle: []const u8, shaderHandle: []const u8) !MeshRenderer {
        return MeshRenderer{
            .meshHandle = AssetHandle.init(meshHandle),
            .tint = rl.Color.white,
            .material = try rl.loadMaterialDefault(),
            .shaderHandle = AssetHandle.init(shaderHandle),
        };
    }

    pub fn deinit(self: *MeshRenderer, allocator: std.mem.Allocator) void {
        _ = allocator;
        rl.unloadMaterial(self.material);
    }

    pub fn drawMesh(self: *MeshRenderer, position: rl.Vector3, scale: rl.Vector3, rotation: rl.Quaternion, assetManager: *AssetManager) void {
        // Get transform matrix (rotation -> scale -> translation)
        const matScale = rl.Matrix.scale(scale.x, scale.y, scale.z);
        const matRotation = rotation.toMatrix();
        const matTranslation = rl.Matrix.translate(position.x, position.y, position.z);
        const matTransform = matScale.multiply(matRotation).multiply(matTranslation);

        // self.material.shader = self.shaderHandle.*;
        const shader = assetManager.shaderStore.get(self.shaderHandle.asSlice()) catch unreachable;
        const locModel = rl.getShaderLocation(shader.*, "worldPos");
        const locTime = rl.getShaderLocation(shader.*, "time");
        rl.setShaderValue(self.material.shader, locModel, &position, .vec3);
        rl.setShaderValue(self.material.shader, locTime, &rl.getTime(), .float);
        const mesh = assetManager.meshStore.get(self.meshHandle.asSlice()) catch unreachable;
        mesh.draw(self.material, matTransform);
    }
};
