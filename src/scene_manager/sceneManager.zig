const std = @import("std");
const Scene = @import("scene.zig").Scene;

pub const SceneManager = struct {
    const Self = @This();

    const Stage = struct {
        id: []const u8,

        /// Creates a fully initialized Scene
        createFn: *const fn (std.mem.Allocator) anyerror!Scene,

        /// Cached instance (for lazy scenes)
        scene: ?Scene,
    };

    allocator: std.mem.Allocator,
    registry: std.ArrayList(Stage),

    current: Scene,
    currentId: ?[]const u8,
    nextStageId: ?[]const u8,

    // -------------------------
    // init
    // -------------------------
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .registry = std.ArrayList(Stage).empty,
            .current = undefined,
            .currentId = null,
            .nextStageId = null,
        };
    }

    // -------------------------
    // register
    // -------------------------
    pub fn register(self: *Self, id: []const u8, comptime SceneType: type) !void {
        const factory = struct {
            fn create(alloc: std.mem.Allocator) !Scene {
                const scene_obj = try alloc.create(SceneType);
                scene_obj.* = try SceneType.init(alloc);
                return Scene.init(scene_obj);
            }
        };

        try self.registry.append(self.allocator, .{
            .id = id,
            .createFn = factory.create,
            .scene = null,
        });
    }

    // -------------------------
    // schedule
    // -------------------------
    pub fn scheduleSceneSwitch(self: *Self, id: []const u8) !void {
        for (self.registry.items) |stage| {
            if (std.mem.eql(u8, stage.id, id)) {
                self.nextStageId = id;
                return;
            }
        }
        return error.SceneNotFound;
    }

    // -------------------------
    // performSwitch
    // -------------------------
    pub fn performSwitch(self: *Self) !void {
        const id = self.nextStageId orelse return;

        var stage: *Stage = undefined;
        for (self.registry.items) |*s| {
            if (std.mem.eql(u8, s.id, id)) {
                stage = s;
                break;
            }
        }

        if (self.currentId) |curId| {
            if (std.mem.eql(u8, curId, id)) {
                return;
            }
        }

        // Lazy init
        if (stage.scene == null) {
            stage.scene = try stage.createFn(self.allocator);
        }

        // Exit & destroy old scene
        if (self.currentId) |_| {
            self.current.exit();
            self.current.deinit(self.allocator);
        }

        // Install new scene
        self.current = stage.scene.?;
        self.currentId = self.nextStageId;

        try self.current.enter();

        self.nextStageId = null;
    }
};
