const std = @import("std");
const rl = @import("raylib");
const Transform = @import("transform.zig").Transform;

pub const MeshRendererSer = struct {
    tint: rl.Color,
};

pub const MeshRenderer = struct {
    tint: rl.Color,
    material: rl.Material,
    meshHandle: *rl.Mesh,
    shaderHandle: *rl.Shader,

    pub fn serializable(self: *MeshRenderer) MeshRendererSer {
        return .{
            .tint = self.tint,
        };
    }

    pub fn init(meshHandle: *rl.Mesh, shaderHandle: *rl.Shader) !MeshRenderer {
        return MeshRenderer{
            .meshHandle = meshHandle,
            .tint = rl.Color.white,
            .material = try rl.loadMaterialDefault(),
            .shaderHandle = shaderHandle,
        };
    }

    pub fn deinit(self: *MeshRenderer, allocator: std.mem.Allocator) void {
        _ = allocator;
        rl.unloadMaterial(self.material);
    }

    pub fn drawMesh(self: *MeshRenderer, position: rl.Vector3, scale: rl.Vector3, rotation: rl.Quaternion) void {
        // Get transform matrix (rotation -> scale -> translation)
        const matScale = rl.Matrix.scale(scale.x, scale.y, scale.z);
        const matRotation = rotation.toMatrix();
        const matTranslation = rl.Matrix.translate(position.x, position.y, position.z);
        const matTransform = matScale.multiply(matRotation).multiply(matTranslation);

        // self.material.shader = self.shaderHandle.*;
        const locModel = rl.getShaderLocation(self.material.shader, "worldPos");
        const locTime = rl.getShaderLocation(self.material.shader, "time");
        rl.setShaderValue(self.material.shader, locModel, &position, .vec3);
        rl.setShaderValue(self.material.shader, locTime, &rl.getTime(), .float);
        // std.debug.print("asdsadsad", .{});
        // const color = self.tint;
        // const colorTint = rl.Color.white;
        self.meshHandle.draw(self.material, matTransform);
    }
};
