pub const Scene = struct {
    scene: *anyopaque,

    enterFn: *const fn (*anyopaque) anyerror!void,
    fixedUpdateFn: *const fn (*anyopaque, f32) void,
    updateFn: *const fn (*anyopaque) void,
    renderFn: *const fn (*anyopaque, f32) anyerror!void,
    renderUIFn: *const fn (*anyopaque) anyerror!void,
    exitFn: *const fn (*anyopaque) void,

    pub fn init(scene_ptr: anytype) Scene {
        const T = @TypeOf(scene_ptr);
        const gen = struct {
            fn enter(ptr: *anyopaque) !void {
                const scene: T = @ptrCast(@alignCast(ptr));
                try scene.start();
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
            .enterFn = gen.enter,
            .fixedUpdateFn = gen.fixedUpdate,
            .updateFn = gen.update,
            .renderFn = gen.render,
            .renderUIFn = gen.renderUI,
            .exitFn = gen.exit,
        };
    }

    pub fn enter(self: *Scene) !void {
        try self.enterFn(self.scene);
    }
    pub fn fixedUpdate(self: *Scene, fixedDeltaTime: f32) void {
        self.fixedUpdateFn(self.scene, fixedDeltaTime);
    }
    pub fn update(self: *Scene) void {
        self.updateFn(self.scene);
    }
    pub fn render(self: *Scene, alphalerp: f32) !void {
        try self.renderFn(self.scene, alphalerp);
    }
    pub fn renderUI(self: *Scene) !void {
        try self.renderUIFn(self.scene);
    }
    pub fn exit(self: *Scene) void {
        self.exitFn(self.scene);
    }
};
