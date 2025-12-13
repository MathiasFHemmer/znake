const std = @import("std");
const rl = @import("raylib");
const SceneManager = @import("./scene_manager/sceneManager.zig").SceneManager;
const GameScene = @import("game.zig").GameScene;
const MenuScene = @import("menu.zig").MenuScene;

pub const std_options: std.Options = .{
    // Set the log level to info
    .log_level = .debug,
};

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Snake Game (Does极)");
    defer rl.closeWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var cam = rl.Camera3D{
        .position = rl.Vector3{ .x = 10, .y = 10, .z = 10 },
        .target = rl.Vector3{ .x = 0, .y = 0, .z = 0 },
        .up = rl.Vector3{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = rl.CameraProjection.perspective,
    };

    var gameScene = try GameScene.init(&cam, gpa.allocator());
    var gameSceneWrapper = gameScene.asScene();
    var menuScene = MenuScene.init(&cam);
    var menuSceneWrapper = menuScene.asScene();
    var sceneManager = try SceneManager.init(&menuSceneWrapper);

    const target_fps: f32 = 30.0;
    const dt: f32 = 1.0 / target_fps;

    var accumulator: f32 = 0;
    var alphaDt: f32 = 0;
    while (!rl.windowShouldClose()) {
        accumulator += @min(rl.getFrameTime(), 0.25);
        while (accumulator >= dt) {
            sceneManager.currentScene.fixedUpdate(dt);
            accumulator -= dt;
        }
        alphaDt = accumulator / dt;
        sceneManager.currentScene.update();

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);

        try sceneManager.currentScene.render(alphaDt);
        try sceneManager.currentScene.renderUI();
        drawWorldAxes(cam);
        rl.endDrawing();

        try sceneManager.performSwitch();
        if (rl.isKeyPressed(.space)) {
            sceneManager.scheduleSceneSwitch(&gameSceneWrapper);
        }
    }
    gameScene.deinit();
}

pub fn drawWorldAxes(camera: rl.Camera3D) void {
    const axisLength: f32 = 10.0;
    const origin = rl.Vector3.zero();
    // std.time.sleep(1000 * 1000 * 100);
    rl.beginMode3D(camera);

    rl.drawLine3D(origin, rl.Vector3{ .x = axisLength, .y = 0, .z = 0 }, rl.Color.red);
    rl.drawLine3D(origin, rl.Vector3{ .x = 0, .y = axisLength, .z = 0 }, rl.Color.green);
    rl.drawLine3D(origin, rl.Vector3{ .x = 0, .y = 0, .z = axisLength }, rl.Color.blue);

    rl.endMode3D();
    rl.drawFPS(10, 10);
    drawAxisLabel(rl.Vector3{ .x = axisLength + 0.5, .y = 0, .z = 0 }, "X", rl.Color.red, camera);
    drawAxisLabel(rl.Vector3{ .x = 0, .y = axisLength + 0.5, .z = 0 }, "Y", rl.Color.green, camera);
    drawAxisLabel(rl.Vector3{ .x = 0, .y = 0, .z = axisLength + 0.5 }, "Z", rl.Color.blue, camera);
}

fn drawAxisLabel(position: rl.Vector3, text: [:0]const u8, color: rl.Color, camera: rl.Camera3D) void {
    const screenPos = rl.getWorldToScreen(position, camera);
    rl.drawText(text, @intFromFloat(screenPos.x), @intFromFloat(screenPos.y), 20, color);
}
