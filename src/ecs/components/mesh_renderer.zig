const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager/asset_manager.zig").AssetManager;
const AssetHandle = @import("asset_handle.zig").AssetHandle;
const Transform = @import("transform.zig").Transform;

pub const MeshRendererSer = struct {
    tint: rl.Color,
};

pub const MeshRenderer = struct {
    tint: rl.Color,
    material: rl.Material,
    meshHandle: AssetHandle,
    shaderHandle: AssetHandle,

    pub fn serialize(self: MeshRenderer, writer: *std.io.Writer) !void {
        return writer.writeAll(&self.meshHandle.key);
    }

    pub fn deserialize(reader: *std.io.Reader, allocator: std.mem.Allocator) !MeshRenderer {
        _ = allocator;
        //const len = try reader.takeInt(u32, .little);
        const key = try reader.take(64);
        return MeshRenderer{
            .tint = rl.Color.white,
            .material = try rl.loadMaterialDefault(),
            .meshHandle = AssetHandle.init(key),
            .shaderHandle = AssetHandle.init(""),
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
        // std.debug.print("asdsadsad", .{});
        // const color = self.tint;
        // const colorTint = rl.Color.white;
        const mesh = assetManager.meshStore.get(self.meshHandle.asSlice()) catch unreachable;
        mesh.draw(self.material, matTransform);
    }
};
