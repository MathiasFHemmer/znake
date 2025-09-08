const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");
const Apple = @import("../entities/apple.zig");

const timer_trigger: f32 = 0.05;
var timer_acc: f32 = timer_trigger;
var apples: i32 = 0;
pub fn check_spawn_apple(world: *World, dt: f32) !void {
    // _ = dt;
    if (timer_acc >= timer_trigger) {
        timer_acc -= timer_trigger;
        const rng = std.crypto.random;
        const pos = rl.Vector3.init(rng.float(f32) * 3, 0, rng.float(f32) * 3);
        _ = try Apple.create(world, pos);
        apples += 1;
        std.debug.print("Apples {any}\n", .{apples});
    }
    timer_acc += dt;
}
