const std = @import("std");
const Scene = @import("scene.zig").Scene;

pub const SceneManager = struct {
    currentScene: *Scene,
    nextScene: ?*Scene,
    switchScene: bool,

    pub fn init(scene: *Scene) !SceneManager {
        try scene.enter();
        return SceneManager{
            .currentScene = scene,
            .nextScene = null,
            .switchScene = false,
        };
    }
    pub fn scheduleSceneSwitch(self: *SceneManager, newScene: *Scene) void {
        self.nextScene = newScene;
        self.switchScene = true;
    }

    pub fn performSwitch(self: *SceneManager) !void {
        if (self.switchScene and self.nextScene != null) {
            self.currentScene.exit();
            // Enter the new scene
            try self.nextScene.?.enter();
            self.currentScene = self.nextScene.?;
            self.nextScene = null;
            self.switchScene = false;
        }
    }
};
