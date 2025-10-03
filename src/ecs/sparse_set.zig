const std = @import("std");
const Entity = @import("ecs.zig").Entity;
const logger = std.log.scoped(.SparseSet);

pub fn SparseSet(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        // Contains the Data itself
        dense: std.array_list.Aligned(T, null),
        // Contains all entities that has this component
        entities: std.array_list.Aligned(Entity, null),
        // Maps the Entity to the index of the Dense array
        sparse: std.AutoHashMap(Entity, u32),

        pub fn init(allocator: std.mem.Allocator) SparseSet(T) {
            logger.debug("Initializing SparseSet({any})...", .{T});
            return SparseSet(T){
                .allocator = allocator,
                .dense = .empty,
                .entities = .empty,
                .sparse = .init(allocator),
            };
        }

        pub fn print(self: *Self) void {
            logger.debug("SparseSet({any}):", .{T});
            logger.debug("Dense: ({any}):", .{self.dense.items.len + 1});
            logger.debug("Sparse:", .{});
            var it = self.sparse.keyIterator();
            while (it.next()) |key| {
                logger.debug("Entity({d}) at ({d}):", .{ key.*, self.sparse.get(key.*).? });
            }

            logger.debug("Entities: ({any}):", .{self.entities.items});
        }

        pub fn deinit(self: *Self) void {
            logger.debug("Deinitializing SparseSet({any})", .{T});
            self.dense.deinit(self.allocator);
            self.entities.deinit(self.allocator);
            self.sparse.deinit();
        }

        pub fn add(self: *Self, entity: Entity, data: T) !void {
            logger.debug("Adding data {any} to SparseSet on entity {any}", .{ entity, T });
            const index: u32 = @intCast(self.dense.items.len);
            try self.dense.append(self.allocator, data);
            try self.entities.append(self.allocator, entity);
            try self.sparse.put(entity, index);
        }

        // Gets a pointer to an Entity Component
        // Looks for the entity in the Sparse set first. If it exists, extract the index from the Sparse set and uses it as a key in the Dense set
        pub fn get(self: *Self, entity: Entity) ?*T {
            // self.print();
            logger.debug("Looking for component {any} of entity {any}", .{ T, entity });
            if (self.sparse.get(entity)) |index| {
                logger.debug("Entity {any} contains component at Dense({d})", .{ entity, index });
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

        pub fn canSerialize(self: *Self, entity: Entity) bool {
            if (self.sparse.get(entity)) |_| return true;
            return false;
        }

        pub fn serialize(self: *Self, entity: Entity, writer: *std.io.Writer) !void {
            if (self.sparse.get(entity)) |idx| {
                const item = &self.dense.items[idx];
                try std.json.Stringify.value(@typeName(T), .{}, writer);
                try writer.writeByte(':');
                if (@hasDecl(@TypeOf(item.*), "serializable")) {
                    try std.json.Stringify.value(item.serializable(), .{
                        .whitespace = .indent_2,
                    }, writer);
                } else {
                    try std.json.Stringify.value(item, .{
                        .whitespace = .indent_2,
                    }, writer);
                }
            }
        }

        pub fn remove(self: *Self, entity: Entity) void {
            logger.debug("Removing componenet {any} from Entity({d})", .{ T, entity });
            const index = self.sparse.get(entity) orelse return;
            _ = self.sparse.remove(entity);
            const lastIndex = self.dense.items.len - 1;
            if (index == lastIndex) {
                _ = self.dense.pop();
                _ = self.entities.pop();
                return;
            }
            const swapped = self.entities.items[lastIndex];
            _ = self.entities.swapRemove(index);
            _ = self.dense.swapRemove(index);
            self.sparse.put(swapped, index) catch unreachable;
        }
    };
}

test "testing" {
    const alloc = std.testing.allocator;
    var set = SparseSet(u32).init(alloc);
    defer set.deinit();

    try set.add(1, 42);
    try std.testing.expect(set.dense.items[0] == 42);
    try std.testing.expect(set.sparse.get(1) == 0);
    try std.testing.expect(set.entities.items[0] == 1);

    try set.add(2, 69);
    try std.testing.expect(set.dense.items[1] == 69);
    try std.testing.expect(set.sparse.get(2) == 1);
    try std.testing.expect(set.entities.items[1] == 2);

    try set.add(3, 420);
    try std.testing.expect(set.dense.items[2] == 420);
    try std.testing.expect(set.sparse.get(3) == 2);
    try std.testing.expect(set.entities.items[2] == 3);

    set.remove(3);
    try std.testing.expect(set.dense.items.len == 2);
    try std.testing.expect(set.sparse.contains(3) == false);
    try std.testing.expect(set.entities.items.len == 2);

    try std.testing.expect(set.dense.items[0] == 42);
    try std.testing.expect(set.sparse.get(1) == 0);
    try std.testing.expect(set.entities.items[0] == 1);
    try std.testing.expect(set.dense.items[1] == 69);
    try std.testing.expect(set.sparse.get(2) == 1);
    try std.testing.expect(set.entities.items[1] == 2);

    try set.add(3, 420);
    try std.testing.expect(set.dense.items[2] == 420);
    try std.testing.expect(set.sparse.get(3) == 2);
    try std.testing.expect(set.entities.items[2] == 3);

    set.remove(2);
    try std.testing.expect(set.dense.items.len == 2);
    try std.testing.expect(set.sparse.contains(2) == false);
    try std.testing.expect(set.entities.items.len == 2);

    try std.testing.expect(set.dense.items[0] == 42);
    try std.testing.expect(set.sparse.get(1) == 0);
    try std.testing.expect(set.entities.items[0] == 1);
    try std.testing.expect(set.dense.items[1] == 420);
    try std.testing.expect(set.sparse.get(3) == 1);
    try std.testing.expect(set.entities.items[1] == 3);
}
