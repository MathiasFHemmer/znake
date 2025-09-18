const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;
const Entity = @import("../ecs.zig").Entity;
const math = @import("../../math/math.zig");
const Spike = @import("../entities/spike.zig");

const timer_trigger: f32 = 4;
var timer_acc: f32 = timer_trigger;
var spikes: i32 = 0;
pub fn spike_spawner(world: *World, dt: f32) !void {
    if (timer_acc >= timer_trigger) {
        timer_acc -= timer_trigger;
        if (world.state.spikes <= 10) {
            const rng = std.crypto.random;
            const pos = rl.Vector3.init(rng.float(f32) * 9, 0, rng.float(f32) * 9);
            _ = try Spike.create(world, pos);
            world.state.spikes += 1;
        }
    }
    timer_acc += dt;
}
