const std = @import("std");
const rl = @import("raylib");
const SceneManager = @import("./scene_manager/sceneManager.zig").SceneManager;
const GameScene = @import("game.zig").GameScene;
const MenuScene = @import("menu.zig").MenuScene;
const log2f = @import("./log_to_file.zig").log_to_file;

pub const std_options: std.Options = .{
    // Set the log level to info
    .log_level = .info,
    .logFn = log2f,
};

pub fn main() !void {
    const screenWidth = 960;
    const screenHeight = 720;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "Snake Game (Does极)");
    // rl.setExitKey(rl.KeyboardKey.null);
    // rl.toggleFullscreen();
    defer rl.closeWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var sceneManager = SceneManager.init(gpa.allocator());
    defer sceneManager.deinit();

    try sceneManager.register("game", GameScene);
    try sceneManager.register("menu", MenuScene);
    try sceneManager.scheduleSceneSwitch("menu");
    try sceneManager.performSwitch();

    const target_fps: f32 = 30.0;
    const dt: f32 = 1.0 / target_fps;

    var accumulator: f32 = 0;
    var alphaDt: f32 = 0;
    while (!sceneManager.exit and !rl.windowShouldClose()) {
        accumulator += @min(rl.getFrameTime(), 0.25);
        while (accumulator >= dt) {
            sceneManager.current.fixedUpdate(dt);
            accumulator -= dt;
        }
        alphaDt = accumulator / dt;
        sceneManager.current.update();

        rl.beginDrawing();
        try sceneManager.current.render(alphaDt);
        try sceneManager.current.renderUI();
        rl.endDrawing();

        try sceneManager.performSwitch();
    }
}
