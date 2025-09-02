const std = @import("std");
const rl = @import("raylib");

const logger = std.log.scoped(.mesh_store);

pub const MeshStore = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    meshes: std.StringHashMap(Entry),

    const Entry = struct {
        asset: rl.Mesh,
        ref_count: usize,
    };

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .meshes = std.StringHashMap(Entry).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.meshes.valueIterator();
        while (it.next()) |entry| {
            unloadMesh(self.allocator, entry.asset);
        }

        self.meshes.deinit();
    }

    pub fn add(self: *Self, key: []const u8, mesh: rl.Mesh) !*rl.Mesh {
        logger.info("Adding new Mesh to store", .{});
        if (self.meshes.contains(key)) {
            std.debug.panic("Mesh {s} is already present on store!", .{key});
            return error.AssetKeyAlreadyExists;
        }

        try self.meshes.put(key, .{
            .asset = copyMesh(&mesh),
            .ref_count = 0,
        });
        const newMesh = try self.get(key);

        logger.info("Uploading new Mesh to GPU", .{});
        rl.uploadMesh(newMesh, false);
        logger.info("New mesh {any} uploaded!", .{newMesh.vaoId});
        return newMesh;
    }

    pub fn get(self: *Self, key: []const u8) !*rl.Mesh {
        const entry = self.meshes.getPtr(key);
        if (entry) |e| {
            e.ref_count += 1;
            return &e.asset;
        }
        std.debug.panic("Could not find mesh {s}", .{key});
        return error.AssetKeyNotFound;
    }
};

pub fn copyMesh(mesh: *const rl.Mesh) rl.Mesh {
    var newMesh = mesh.*;

    if (mesh.vertices != null) {
        const vCount: u32 = @intCast(mesh.vertexCount * 3);
        const iCount: u32 = @intCast(mesh.vertexCount * 2);

        newMesh.vertices = @ptrCast(@alignCast(rl.memAlloc(vCount * @sizeOf(f32))));
        newMesh.normals = @ptrCast(@alignCast(rl.memAlloc(vCount * @sizeOf(f32))));
        newMesh.indices = @ptrCast(@alignCast(rl.memAlloc(iCount * @sizeOf(c_ushort))));

        std.mem.copyForwards(f32, newMesh.vertices[0..vCount], mesh.vertices[0..vCount]);
        std.mem.copyForwards(f32, newMesh.normals[0..vCount], mesh.normals[0..vCount]);
        std.mem.copyForwards(c_ushort, newMesh.indices[0..iCount], mesh.indices[0..iCount]);
    }
    return newMesh;
}

// TODO:
// Should I remove the allocations from Raylib and handle the mesh myself, or use MemAlloc for every allocation and compromise my memory management?
pub fn unloadMesh(allocator: std.mem.Allocator, mesh: rl.Mesh) void {
    _ = allocator;
    mesh.unload();
}
