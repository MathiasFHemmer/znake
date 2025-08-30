const std = @import("std");
const Entity = @import("ecs.zig").Entity;

pub fn SparseSet(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        dense: std.ArrayList(T),
        sparse: std.AutoHashMap(Entity, u32),
        entities: std.ArrayList(Entity),

        pub fn init(allocator: std.mem.Allocator) SparseSet(T) {
            return SparseSet(T){
                .allocator = allocator,
                .dense = .init(allocator),
                .sparse = .init(allocator),
                .entities = .init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.dense.deinit();
            self.sparse.deinit();
            self.entities.deinit();
        }

        pub fn add(self: *Self, entity: Entity, data: T) !void {
            try self.dense.append(data);
            try self.entities.append(entity);
            const index: Entity = @intCast(self.dense.items.len - 1);
            try self.sparse.put(entity, index);
        }

        pub fn get(self: *Self, entity: Entity) ?*T {
            if (self.sparse.get(entity)) |index| {
                return &self.dense.items[index];
            }
            return null;
        }

        pub fn getUnsafe(self: *Self, entity: Entity) *T {
            const index = self.sparse.get(entity) orelse std.math.maxInt(u32);
            return &self.dense.items[index];
        }
        pub fn getEntity(self: *Self, index: usize) Entity {
            if (index < self.entities.items.len) {
                return self.entities.items[index];
            }
            return 0;
        }

        pub fn getDenseSlice(self: *Self) []T {
            return self.dense.items;
        }

        pub fn getEntitiesSlice(self: *Self) []Entity {
            return self.entities.items;
        }

        pub fn remove(self: *Self, entity: Entity) void {
            const index = self.sparse.get(entity) orelse return;
            _ = self.sparse.remove(entity);
            const lastIndex = self.dense.items.len - 1;
            if (index == lastIndex) {
                _ = self.dense.pop();
                _ = self.entities.pop();
                return;
            }
            const swapped = self.entities.swapRemove(index);
            _ = self.dense.swapRemove(index);
            self.sparse.put(swapped, index) catch unreachable;
        }
    };
}
