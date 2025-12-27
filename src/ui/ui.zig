const std = @import("std");
const rl = @import("raylib");
const math = @import("../math/math.zig");

const Layout = enum {
    LeftToRight,
    TopToBottom,
};

pub const Dimension = union(enum) {
    const Self = @This();

    fit: f32,
    fixed: f32,

    pub fn add(self: Self, value: f32) Dimension {
        return switch (self) {
            .fit => .{ .fit = self.fit + value },
            .fixed => .{ .fixed = self.fixed + value },
        };
    }

    pub fn unpackDimension(dimension: Dimension) f32 {
        return switch (dimension) {
            .fit => dimension.fit,
            .fixed => dimension.fixed,
        };
    }
};

const Position = math.Vector2;
const Padding = struct { top: f32 = 0, bottom: f32 = 0, left: f32 = 0, right: f32 = 0 };

const Sizing = struct {
    width: Dimension = .{ .fit = 0 },
    height: Dimension = .{ .fit = 0 },
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
        const paddingH = element.padding.top + element.padding.bottom;
        const paddingW = element.padding.left + element.padding.right;

        element.sizing.width = element.sizing.width.add(paddingW);
        element.sizing.height = element.sizing.height.add(paddingH);

        if (element.parent) |parent| {
            const gap = @as(f32, @floatFromInt((@max(parent.children.items.len - 1, 0)))) * parent.gap;

            switch (parent.layout) {
                .LeftToRight => {
                    switch (parent.sizing.width) {
                        .fit => parent.sizing.width.fit += element.sizing.width.unpackDimension() + gap,
                        .fixed => {},
                    }
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.height.fit = @max(element.sizing.height.unpackDimension(), parent.sizing.height.unpackDimension()),
                        .fixed => {},
                    }
                },
                .TopToBottom => {
                    switch (parent.sizing.width) {
                        .fit => parent.sizing.height.fit += element.sizing.height.unpackDimension() + gap,
                        .fixed => {},
                    }
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.width.fit = @max(element.sizing.width.unpackDimension(), parent.sizing.width.unpackDimension()),
                        .fixed => {},
                    }
                },
            }

            self.current = self.current.?.parent;
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

        // Push root
        self.drawStack.append(self.arena.allocator(), .{
            .box = &self.root.?,
            .elementPosition = self.root.?.position,
            .cursorPosition = .init(self.root.?.padding.left, self.root.?.padding.top),
        }) catch unreachable;

        while (self.drawStack.items.len > 0) {
            var item = self.drawStack.pop().?;
            const box = item.box;

            rl.drawRectangle(
                @intFromFloat(item.elementPosition.x),
                @intFromFloat(item.elementPosition.y),
                @intFromFloat(box.sizing.width.unpackDimension()),
                @intFromFloat(box.sizing.height.unpackDimension()),
                box.color,
            );

            for (box.children.items) |*child| {
                const childElementPosition = item.elementPosition.add(item.cursorPosition);

                self.drawStack.append(self.arena.allocator(), .{
                    .box = child,
                    .elementPosition = childElementPosition,
                    .cursorPosition = .init(child.padding.left, child.padding.top),
                }) catch unreachable;

                switch (box.layout) {
                    .LeftToRight => item.cursorPosition.x += child.sizing.width.unpackDimension() + box.gap,
                    .TopToBottom => item.cursorPosition.y += child.sizing.height.unpackDimension() + box.gap,
                }
            }
        }
    }
};
