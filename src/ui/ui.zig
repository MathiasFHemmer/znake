const std = @import("std");
const rl = @import("raylib");
const math = @import("../math/math.zig");

const Layout = enum {
    LeftToRight,
    TopToBottom,
};

pub const Constrain = struct {
    const Self = @This();

    value: f32 = 0,
    min: f32 = std.math.floatMin(f32),
    max: f32 = std.math.floatMax(f32),

    pub const empty: Self = .{};
};

pub const Dimension = union(enum) {
    const Self = @This();

    fit: Constrain,
    fixed: Constrain,

    pub const empty: Self = .{
        .fit = .empty,
    };

    pub fn add(self: Self, value: f32) Self {
        return switch (self) {
            .fit => .{
                .fit = .{
                    .value = self.fit.value + value,
                    .min = self.fit.min,
                    .max = self.fit.max,
                },
            },
            .fixed => .{
                .fixed = .{
                    .value = self.fixed.value + value,
                    .min = self.fixed.min,
                    .max = self.fixed.max,
                },
            },
        };
    }

    pub inline fn applyConstrain(self: Self) Self {
        return switch (self) {
            .fit => |v| .{
                .fit = .{
                    .value = std.math.clamp(v.value, v.min, v.max),
                    .min = v.min,
                    .max = v.max,
                },
            },
            .fixed => |v| .{
                .fixed = .{
                    .value = std.math.clamp(v.value, v.min, v.max),
                    .min = v.min,
                    .max = v.max,
                },
            },
        };
    }

    pub fn unpackDimension(dimension: Self) f32 {
        return switch (dimension) {
            .fit => dimension.fit.value,
            .fixed => dimension.fixed.value,
        };
    }
};

const Position = math.Vector2;
const Padding = struct { top: f32 = 0, bottom: f32 = 0, left: f32 = 0, right: f32 = 0 };

const Sizing = struct {
    width: Dimension = .empty,
    height: Dimension = .empty,
};

pub const Box = struct {
    const Self = @This();

    // Tree
    parent: ?*Self = null,
    children: std.ArrayList(Self) = .empty,

    // Layout
    position: Position = .empty,
    sizing: Sizing = .{},
    padding: Padding = .{},
    gap: f32 = 0,
    layout: Layout = .LeftToRight,

    // Appearence:
    color: rl.Color = rl.Color.pink,

    pub fn init(
        opt: struct {
            layout: Layout = .LeftToRight,
            position: Position = .empty,
            sizing: Sizing = .{},
            padding: Padding = .{},
            gap: f32 = 0,
            color: rl.Color = rl.Color.pink,
        },
    ) Self {
        return Self{
            .parent = null,
            .children = .empty,
            .layout = opt.layout,
            .position = opt.position,
            .sizing = opt.sizing,
            .padding = opt.padding,
            .gap = opt.gap,
            .color = opt.color,
        };
    }

    pub const empty: Self = .{};
};

pub const Canvas = struct {
    const Self = @This();

    const StackItem = struct {
        box: *Box,
        elementPosition: Position,
        cursorPosition: Position,
    };

    arena: std.heap.ArenaAllocator,
    drawStack: std.ArrayList(StackItem),

    root: ?Box,
    current: ?*Box,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .drawStack = .empty,
            .current = null,
            .root = null,
        };
    }

    pub fn openScope(self: *Self, element: Box) void {
        if (self.current) |cur| {
            self.current = cur.children.addOne(self.arena.allocator()) catch unreachable;
            self.current.?.* = element;
            self.current.?.parent = cur;
        } else {
            self.root = element;
            self.current = &self.root.?;
            self.current.?.* = element;
        }
    }

    pub fn closeScope(self: *Self) void {
        const element = self.current.?;

        var main_cursor: f32 = 0;
        var cross_cursor: f32 = 0;
        var line_cross_max: f32 = 0;

        const main_max = switch (element.layout) {
            .LeftToRight => switch (element.sizing.width) {
                .fixed => |v| v.value,
                .fit => |v| v.max,
            },
            .TopToBottom => switch (element.sizing.height) {
                .fixed => |v| v.value,
                .fit => |v| v.max,
            },
        };

        for (element.children.items) |*child| {
            const child_main = switch (element.layout) {
                .LeftToRight => child.sizing.width.unpackDimension(),
                .TopToBottom => child.sizing.height.unpackDimension(),
            };

            const child_cross = switch (element.layout) {
                .LeftToRight => child.sizing.height.unpackDimension(),
                .TopToBottom => child.sizing.width.unpackDimension(),
            };

            if (main_cursor > 0 and main_cursor + child_main > main_max) {
                cross_cursor += line_cross_max + element.gap;
                main_cursor = 0;
                line_cross_max = 0;
            }

            main_cursor += child_main + element.gap;
            line_cross_max = @max(line_cross_max, child_cross);
        }

        // finalize last line
        cross_cursor += line_cross_max;

        const paddingH = element.padding.top + element.padding.bottom;
        const paddingW = element.padding.left + element.padding.right;

        const gap = @as(f32, @floatFromInt((@max(element.children.items.len, 1) - 1))) * element.gap;
        switch (element.layout) {
            .LeftToRight => element.sizing.width = element.sizing.width.add(gap),
            .TopToBottom => element.sizing.height = element.sizing.height.add(gap),
        }
        element.sizing.width = element.sizing.width.add(paddingW).applyConstrain();
        element.sizing.height = element.sizing.height.add(paddingH).applyConstrain();

        if (element.parent) |parent| {
            const w = element.sizing.width.unpackDimension();
            const h = element.sizing.height.unpackDimension();

            switch (parent.layout) {
                .LeftToRight => {
                    switch (parent.sizing.width) {
                        .fit => parent.sizing.width.fit.value += w,
                        .fixed => {},
                    }
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.height.fit.value = @max(parent.sizing.height.fit.value, h),
                        .fixed => {},
                    }
                },
                .TopToBottom => {
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.height.fit.value += h,
                        .fixed => {},
                    }
                    switch (parent.sizing.width) {
                        .fit => parent.sizing.width.fit.value = @max(parent.sizing.width.fit.value, w),
                        .fixed => {},
                    }
                },
            }

            self.current = parent;
        }
    }

    pub fn reset(self: *Self) void {
        _ = self.arena.reset(.retain_capacity);
        self.drawStack = .empty;
        self.root = null;
        self.current = null;
    }

    pub fn draw(self: *Self) void {
        if (self.root == null) return;

        self.drawStack.append(self.arena.allocator(), .{
            .box = &self.root.?,
            .elementPosition = self.root.?.position,
            .cursorPosition = .init(
                self.root.?.padding.left,
                self.root.?.padding.top,
            ),
        }) catch unreachable;

        while (self.drawStack.items.len > 0) {
            var item = self.drawStack.pop().?;
            const box = item.box;

            const box_width = box.sizing.width.unpackDimension();
            const box_height = box.sizing.height.unpackDimension();

            rl.drawRectangle(
                @intFromFloat(item.elementPosition.x),
                @intFromFloat(item.elementPosition.y),
                @intFromFloat(box_width),
                @intFromFloat(box_height),
                box.color,
            );

            var cursor = item.cursorPosition;
            var line_cross_max: f32 = 0;

            const main_limit: f32 = switch (box.layout) {
                .LeftToRight => switch (box.sizing.width) {
                    .fixed => |v| v.value,
                    .fit => |v| v.max,
                },
                .TopToBottom => switch (box.sizing.height) {
                    .fixed => |v| v.value,
                    .fit => |v| v.max,
                },
            };

            const initial_cursor = cursor;

            for (box.children.items) |*child| {
                const child_main = switch (box.layout) {
                    .LeftToRight => child.sizing.width.unpackDimension(),
                    .TopToBottom => child.sizing.height.unpackDimension(),
                };

                const child_cross = switch (box.layout) {
                    .LeftToRight => child.sizing.height.unpackDimension(),
                    .TopToBottom => child.sizing.width.unpackDimension(),
                };

                const current_main = switch (box.layout) {
                    .LeftToRight => cursor.x - initial_cursor.x,
                    .TopToBottom => cursor.y - initial_cursor.y,
                };

                if (current_main > 0 and current_main + child_main > main_limit) {
                    switch (box.layout) {
                        .LeftToRight => {
                            cursor.x = initial_cursor.x;
                            cursor.y += line_cross_max + box.gap;
                        },
                        .TopToBottom => {
                            cursor.y = initial_cursor.y;
                            cursor.x += line_cross_max + box.gap;
                        },
                    }
                    line_cross_max = 0;
                }

                self.drawStack.append(self.arena.allocator(), .{
                    .box = child,
                    .elementPosition = item.elementPosition.add(cursor),
                    .cursorPosition = .init(
                        child.padding.left,
                        child.padding.top,
                    ),
                }) catch unreachable;

                switch (box.layout) {
                    .LeftToRight => cursor.x += child_main + box.gap,
                    .TopToBottom => cursor.y += child_main + box.gap,
                }

                line_cross_max = @max(line_cross_max, child_cross);
            }
        }
    }
};
