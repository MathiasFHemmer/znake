const std = @import("std");
const SparseSet = @import("sparse_set.zig").SparseSet;
const AssetManager = @import("../asset_manager/asset_manager.zig").AssetManager;
const logger = std.log.scoped(.ECS);

pub const Entity = u32;

pub fn ECS(comptime ComponentTypes: type, comptime State: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        assetManager: AssetManager,
        state: State,

        nextEntity: Entity,
        entitiesToRemove: std.array_list.Aligned(Entity, null),

        componentStorage: ComponentStorages,

        const ComponentStorages = blk: {
            var fields: []const std.builtin.Type.StructField = &.{};
            const info = @typeInfo(ComponentTypes).@"struct";

            for (info.fields) |field| {
                const T = field.type;
                const field_type = SparseSet(T);
                fields = fields ++ [1]std.builtin.Type.StructField{
                    .{
                        .name = field.name,
                        .type = field_type,
                        .default_value_ptr = null,
                        .is_comptime = false,
                        .alignment = @alignOf(field_type),
                    },
                };
            }

            break :blk @Type(.{
                .@"struct" = .{
                    .layout = .auto,
                    .fields = fields,
                    .decls = &.{},
                    .is_tuple = false,
                },
            });
        };

        pub fn init(allocator: std.mem.Allocator) !Self {
            var self: Self = .{ .allocator = allocator, .assetManager = try AssetManager.init(allocator), .state = State.init(), .nextEntity = 1, .entitiesToRemove = .empty, .componentStorage = undefined };

            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                const T = field.type;
                const data = SparseSet(T).init(allocator);
                @field(self.componentStorage, field.name) = data;
            }

            return self;
        }

        pub fn printRegistry() void {
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                logger.debug("Component [{s}] Type [{s}] active", .{ field.name, @typeName(field.type) });
            }
        }

        pub fn deinit(self: *Self) void {
            self.assetManager.deinit();
            self.entitiesToRemove.deinit(self.allocator);

            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                @field(self.componentStorage, field.name).deinit();
            }
        }

        pub fn createEntity(self: *Self) Entity {
            logger.debug("Creating new entity...", .{});
            const current = self.nextEntity;
            self.nextEntity += 1;
            logger.debug("Entity {any} created!", .{current});
            return current;
        }

        pub fn addComponent(self: *Self, entity: Entity, component: anytype) void {
            const T: type = @TypeOf(component);
            logger.debug("Adding component {any} to entity {any}...", .{ T, entity });
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                if (field.type == T) {
                    @field(self.componentStorage, field.name).add(entity, component) catch {};
                    return;
                }
            }
            @compileError("Component type " ++ @typeName(T) ++ " not registered in ECS");
        }

        pub fn getComponent(self: *Self, entity: Entity, comptime T: type) ?*T {
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                if (field.type == T) {
                    return @field(self.componentStorage, field.name).get(entity);
                }
            }
            @compileError("Component type " ++ @typeName(T) ++ " not registered in ECS");
        }

        pub fn getComponentEntity(self: *Self, index: usize, comptime T: type) Entity {
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                if (field.type == T) {
                    return @field(self.componentStorage, field.name).getEntity(index);
                }
            }
            @compileError("Component type " ++ @typeName(T) ++ " not registered in ECS");
        }

        pub fn getComponentSet(self: *Self, comptime T: type) *SparseSet(T) {
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                if (field.type == T) {
                    return &@field(self.componentStorage, field.name);
                }
            }
            @compileError("Component type " ++ @typeName(T) ++ " not registered in ECS");
        }

        pub fn markForRemoval(self: *Self, entity: Entity) void {
            self.entitiesToRemove.append(self.allocator, entity) catch unreachable;
        }

        // This removes an entity and all its associated components.
        // Do not use this inside a query!
        pub fn removeEntity(self: *Self, entity: Entity) void {
            inline for (@typeInfo(ComponentTypes).@"struct".fields) |field| {
                @field(self.componentStorage, field.name).remove(entity);
            }
        }

        pub fn flushRemoval(self: *Self) void {
            for (self.entitiesToRemove.items) |entity| {
                self.removeEntity(entity);
            }
            self.entitiesToRemove.clearRetainingCapacity();
        }

        pub fn query(self: *Self, comptime Components: type) Query(Components) {
            return Query(Components).init(self);
        }
        pub fn Query(comptime Components: type) type {
            return struct {
                sets: Sets,

                const Sets = blk: {
                    var fields: []const std.builtin.Type.StructField = &.{};
                    const info = @typeInfo(Components).@"struct";

                    for (info.fields) |field| {
                        const T = field.type;
                        const field_type = *SparseSet(T);
                        fields = fields ++ [1]std.builtin.Type.StructField{
                            .{
                                .name = field.name,
                                .type = field_type,
                                .default_value_ptr = null,
                                .is_comptime = false,
                                .alignment = @alignOf(field_type),
                            },
                        };
                    }

                    break :blk @Type(.{
                        .@"struct" = .{
                            .layout = .auto,
                            .fields = fields,
                            .decls = &.{},
                            .is_tuple = false,
                        },
                    });
                };

                pub fn init(ecs: *Self) @This() {
                    var _query: @This() = undefined;

                    inline for (@typeInfo(Components).@"struct".fields) |field| {
                        const T = field.type;
                        @field(_query.sets, field.name) = ecs.getComponentSet(T);
                    }

                    return _query;
                }
            };
        }
    };
}
