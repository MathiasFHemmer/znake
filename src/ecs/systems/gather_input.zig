const std = @import("std");
const rl = @import("raylib");
const AssetManager = @import("../../asset_manager//asset_manager.zig").AssetManager;
const AssetStore = @import("../../asset_manager/asset_store.zig").AssetStore;
const Components = @import("../components.zig");
const WorldEnv = @import("../world.zig");
const World = WorldEnv.World;

pub fn gatherInput(world: *World) void {
    world.state.playerInput.movement = .zero();
    if (rl.isKeyDown(.w)) world.state.playerInput.movement.y = 1;
    if (rl.isKeyDown(.s)) world.state.playerInput.movement.y = -1;
    if (rl.isKeyDown(.a)) world.state.playerInput.movement.x = 1;
    if (rl.isKeyDown(.d)) world.state.playerInput.movement.x = -1;
}
