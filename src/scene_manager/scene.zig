//! Scene provides a generic interface for managing scene objects in the game.
//!
//! A Scene wraps a scene object (any struct with methods: start, fixedUpdate, update, render, renderUI, exit)
//! and provides a unified interface through function pointers.
//!
//! Usage:
//!   1. Define a scene struct with the required methods.
//!   2. Create an instance of your scene struct.
//!   3. Call Scene.init(&scene_instance) to create a Scene wrapper.
//!   4. Use the Scene methods to manage the lifecycle.
//!
//! Required scene methods:
//!   - init(allocator: std.mem.Allocator) !@This(): Initialize the scene with allocator.
//!   - deinit(self: *@This(), allocator: std.mem.Allocator) void: Deinitialize the scene.
//!   - enter() !void: Called when entering the scene.
//!   - fixedUpdate(f32): Called at fixed time intervals (e.g., physics updates).
//!   - update(): Called every frame.
//!   - render(f32) !void: Called to render the scene, with interpolation factor.
//!   - renderUI() !void: Called to render UI elements.
//!   - exit(): Called when exiting the scene.
const std = @import("std");
const rl = @import("raylib");
const SceneManager = @import("./sceneManager.zig").SceneManager;

pub const Scene = struct {
    scene: *anyopaque,
    sceneManager: *SceneManager,

    enterFn: *const fn (*anyopaque) anyerror!void,
    fixedUpdateFn: *const fn (*anyopaque, f32) void,
    updateFn: *const fn (*anyopaque) void,
    renderFn: *const fn (*anyopaque, f32) anyerror!void,
    renderUIFn: *const fn (*anyopaque) anyerror!void,
    exitFn: *const fn (*anyopaque) void,
    deinitFn: *const fn (*anyopaque, std.mem.Allocator) void,

    /// Initializes a Scene wrapper around a scene object.
    ///
    /// The scene object must have the following methods:
    ///   - init(allocator: std.mem.Allocator) !@This()
    ///   - deinit(self: *@This(), allocator: std.mem.Allocator) void
    ///   - enter() !void
    ///   - fixedUpdate(f32) void
    ///   - update() void
    ///   - render(f32) !void
    ///   - renderUI() !void
    ///   - exit() void
    ///
    /// Parameters:
    ///   - scene_ptr: Pointer to the scene object instance.
    ///
    /// Returns: A Scene wrapper that can be used with SceneManager.
    pub fn init(scene_ptr: anytype, sceneManager: *SceneManager) Scene {
        const T = @TypeOf(scene_ptr);
        const gen = struct {
            fn enter(ptr: *anyopaque) !void {
                const scene: T = @ptrCast(@alignCast(ptr));
                try scene.enter();
            }
            fn deinit(ptr: *anyopaque, alloc: std.mem.Allocator) void {
                const scene: T = @ptrCast(@alignCast(ptr));
                scene.deinit(alloc);
            }
            fn fixedUpdate(ptr: *anyopaque, fixedDeltaTime: f32) void {
                const scene: T = @ptrCast(@alignCast(ptr));
                scene.fixedUpdate(fixedDeltaTime);
            }
            fn update(ptr: *anyopaque) void {
                const scene: T = @ptrCast(@alignCast(ptr));
                scene.update();
            }
            fn render(ptr: *anyopaque, alphaLerp: f32) !void {
                const scene: T = @ptrCast(@alignCast(ptr));
                try scene.render(alphaLerp);
            }
            fn renderUI(ptr: *anyopaque) !void {
                const scene: T = @ptrCast(@alignCast(ptr));
                try scene.renderUI();
            }

            fn exit(ptr: *anyopaque) void {
                const scene: T = @ptrCast(@alignCast(ptr));
                scene.exit();
            }
        };

        return Scene{
            .scene = scene_ptr,
            .sceneManager = sceneManager,
            .enterFn = gen.enter,
            .deinitFn = gen.deinit,
            .fixedUpdateFn = gen.fixedUpdate,
            .updateFn = gen.update,
            .renderFn = gen.render,
            .renderUIFn = gen.renderUI,
            .exitFn = gen.exit,
        };
    }

    /// Enters the scene, calling the scene object's enter() method.
    /// Typically called by SceneManager when switching to this scene.
    pub fn enter(self: *Scene) !void {
        try self.enterFn(self.scene);
    }

    /// Deinitializes the scene, calling the scene object's deinit(allocator) method.
    /// Typically called by SceneManager when switching away from this scene.
    pub fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        self.deinitFn(self.scene, allocator);
    }

    /// Updates the scene at fixed time intervals, calling fixedUpdate(fixedDeltaTime).
    /// Used for physics or other time-sensitive updates.
    pub fn fixedUpdate(self: *Scene, fixedDeltaTime: f32) void {
        self.fixedUpdateFn(self.scene, fixedDeltaTime);
    }

    /// Updates the scene every frame, calling update().
    /// Used for general game logic updates.
    pub fn update(self: *Scene) void {
        self.updateFn(self.scene);
    }

    /// Renders the scene, calling render(alphaLerp).
    /// The alphaLerp parameter is used for interpolation between frames.
    pub fn render(self: *Scene, alphalerp: f32) !void {
        try self.renderFn(self.scene, alphalerp);
    }

    /// Renders UI elements, calling renderUI().
    /// Called after render() for overlay elements.
    pub fn renderUI(self: *Scene) !void {
        try self.renderUIFn(self.scene);
    }

    /// Exits the scene, calling exit().
    /// Called when switching away from this scene.
    pub fn exit(self: *Scene) void {
        self.exitFn(self.scene);
    }
};
