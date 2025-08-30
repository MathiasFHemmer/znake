const std = @import("std");
const rl = @import("raylib");
const AssetStore = @import("../asset_manager.zig").AssetStore;
const Transform = @import("transform.zig").Transform;

pub const MeshRenderer = struct {
    mesh: rl.Mesh,
    tint: rl.Color,
    material: rl.Material,
    shaderHandle: *rl.Shader,

    pub fn init(mesh: rl.Mesh, shaderStore: *AssetStore(rl.Shader)) !MeshRenderer {
        return MeshRenderer{
            .mesh = mesh,
            .tint = rl.Color.white,
            .material = try rl.loadMaterialDefault(),
            .shaderHandle = try shaderStore.get("shaders/snek"),
        };
    }

    pub fn deinit(self: *MeshRenderer, allocator: std.mem.Allocator, shaderStore: *AssetStore(rl.Shader)) void {
        _ = allocator;
        shaderStore.release("shaders/snek");
        rl.unloadMaterial(self.material);
        rl.unloadMesh(self.mesh);
    }

    pub fn drawMesh(self: *MeshRenderer, position: rl.Vector3, scale: rl.Vector3, rotation: rl.Quaternion) void {
        // Get transform matrix (rotation -> scale -> translation)
        const matScale = rl.Matrix.scale(scale.x, scale.y, scale.z);
        const matRotation = rotation.toMatrix();
        const matTranslation = rl.Matrix.translate(position.x, position.y, position.z);
        const matTransform = matScale.multiply(matRotation).multiply(matTranslation);

        self.material.shader = self.shaderHandle.*;
        const locModel = rl.getShaderLocation(self.material.shader, "worldPos");
        const locTime = rl.getShaderLocation(self.material.shader, "time");
        rl.setShaderValue(self.material.shader, locModel, &position, .vec3);
        rl.setShaderValue(self.material.shader, locTime, &rl.getTime(), .float);

        // const color = self.tint;
        // const colorTint = rl.Color.white;

        self.mesh.draw(self.material, matTransform);
    }
};
