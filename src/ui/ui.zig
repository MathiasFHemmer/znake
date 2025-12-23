const std = @import("std");
const rl = @import("raylib");

pub const LayoutDirection = enum {
    LEFT_TO_RIGHT,
    TOP_TO_BOTTOM,
};

pub const Margin = union(enum) {
    fixed: rl.Vector2,
    relative: rl.Vector2,
};

const Phase = enum {
    measure,
    render,
};

const LayoutNode = struct {
    origin: rl.Vector2,
    cursor: rl.Vector2,
    measured_size: rl.Vector2,
    layout: LayoutDirection,
    margin: Margin,

    resolved_origin: rl.Vector2,
};

pub const UI = struct {
    allocator: std.mem.Allocator,

    mouse_pos: rl.Vector2,
    mouse_down: bool,

    hot: ?u64 = null,
    active: ?u64 = null,

    layouts: std.ArrayList(LayoutNode),
    layout_stack_len: usize = 0,

    phase: Phase = .measure,

    pub fn init(allocator: std.mem.Allocator) UI {
        return .{
            .allocator = allocator,
            .mouse_pos = .{ .x = 0, .y = 0 },
            .mouse_down = false,
            .layouts = std.ArrayList(LayoutNode).initCapacity(allocator, 32) catch unreachable,
        };
    }

    pub fn deinit(self: *UI) void {
        self.layouts.deinit(self.allocator);
    }

    // ---------------- frame ----------------

    pub fn run(
        self: *UI,
        ctx: anytype,
        drawFn: fn (*UI, @TypeOf(ctx)) void,
    ) void {
        // input
        self.mouse_pos = rl.getMousePosition();
        self.mouse_down = rl.isMouseButtonDown(.left);
        self.hot = null;

        // -------- measure pass --------
        self.phase = .measure;
        self.layout_stack_len = 0;
        self.layouts.clearRetainingCapacity();

        drawFn(self, ctx);

        self.resolveLayouts();

        // -------- render pass --------
        self.phase = .render;
        self.layout_stack_len = 0;

        for (self.layouts.items) |*n| {
            n.cursor = n.resolved_origin;
        }

        drawFn(self, ctx);

        if (!self.mouse_down) {
            self.active = null;
        }
    }

    // ---------------- layout ----------------

    pub fn beginLayout(
        self: *UI,
        layout: LayoutDirection,
        opts: struct { margin: Margin = .{ .fixed = .init(0, 0) } },
    ) void {
        const index = self.layout_stack_len;
        self.layout_stack_len += 1;

        if (self.phase == .measure) {
            const origin =
                if (index == 0)
                    rl.Vector2{ .x = 0, .y = 0 }
                else
                    self.layouts.items[index - 1].cursor;

            self.layouts.append(self.allocator, .{
                .origin = origin,
                .cursor = origin,
                .measured_size = .{ .x = 0, .y = 0 },
                .layout = layout,
                .margin = opts.margin,
                .resolved_origin = origin,
            }) catch unreachable;
        }
    }

    pub fn endLayout(self: *UI) void {
        self.layout_stack_len -= 1;

        if (self.phase == .measure and self.layout_stack_len > 0) {
            const child = &self.layouts.items[self.layout_stack_len];
            const parent = &self.layouts.items[self.layout_stack_len - 1];
            accumulateSize(parent, child.measured_size);
            advanceCursor(parent, child.measured_size);
        }
    }

    fn resolveLayouts(self: *UI) void {
        const screen_w: f32 = @floatFromInt(rl.getScreenWidth());
        const screen_h: f32 = @floatFromInt(rl.getScreenHeight());

        for (self.layouts.items) |*n| {
            var origin = n.origin;

            switch (n.margin) {
                .fixed => |v| {
                    origin.x += v.x;
                    origin.y += v.y;
                },
                .relative => |r| {
                    origin.x = (screen_w - n.measured_size.x) * r.x;
                    origin.y = (screen_h - n.measured_size.y) * r.y;
                },
            }

            n.resolved_origin = origin;
        }
    }

    // ---------------- widgets ----------------

    pub fn button(
        self: *UI,
        label: [:0]const u8,
        opts: struct {
            size: rl.Vector2 = .{ .x = 120, .y = 32 },
        },
    ) bool {
        const id = idFromLabel(label);
        const node = &self.layouts.items[self.layout_stack_len - 1];

        const pos = node.cursor;
        const size = opts.size;

        if (self.phase == .measure) {
            accumulateSize(node, size);
            advanceCursor(node, size);
            return false;
        }

        const bounds = rl.Rectangle{
            .x = pos.x,
            .y = pos.y,
            .width = size.x,
            .height = size.y,
        };

        const hovered = rl.checkCollisionPointRec(self.mouse_pos, bounds);

        if (hovered) {
            self.hot = id;
            if (self.mouse_down and self.active == null) {
                self.active = id;
            }
        }

        const clicked = !self.mouse_down and self.active == id and hovered;
        if (clicked) self.active = null;

        var color = rl.Color.gray;
        if (self.hot == id) color = rl.Color.light_gray;
        if (self.active == id) color = rl.Color.dark_gray;

        rl.drawRectangleRec(bounds, color);
        rl.drawText(
            label,
            @intFromFloat(pos.x + 8),
            @intFromFloat(pos.y + size.y / 2 - 8),
            16,
            rl.Color.black,
        );

        advanceCursor(node, size);
        return clicked;
    }
};

// ---------------- helpers ----------------

fn idFromLabel(label: [:0]const u8) u64 {
    return std.hash.Wyhash.hash(0, label);
}

fn advanceCursor(node: *LayoutNode, size: rl.Vector2) void {
    switch (node.layout) {
        .LEFT_TO_RIGHT => node.cursor.x += size.x,
        .TOP_TO_BOTTOM => node.cursor.y += size.y,
    }
}

fn accumulateSize(node: *LayoutNode, size: rl.Vector2) void {
    switch (node.layout) {
        .LEFT_TO_RIGHT => {
            node.measured_size.x += size.x;
            node.measured_size.y = @max(node.measured_size.y, size.y);
        },
        .TOP_TO_BOTTOM => {
            node.measured_size.y += size.y;
            node.measured_size.x = @max(node.measured_size.x, size.x);
        },
    }
}
