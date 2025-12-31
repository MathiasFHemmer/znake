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
    grow: Constrain,

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
            .grow => |v| .{
                .grow = .{
                    .value = v.value + value,
                    .min = v.min,
                    .max = v.max,
                },
            },
        };
    }

    pub fn set(self: Self, value: f32) Self {
        return switch (self) {
            .fit => |v| .{
                .fit = .{
                    .value = value,
                    .min = v.min,
                    .max = v.max,
                },
            },
            .fixed => |v| .{
                .fixed = .{
                    .value = value,
                    .min = v.min,
                    .max = v.max,
                },
            },
            .grow => |v| .{
                .grow = .{
                    .value = value,
                    .min = v.min,
                    .max = v.max,
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
            .grow => |v| .{
                .grow = .{
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
            .grow => |g| g.value,
        };
    }

    pub fn unpackMax(dimension: Self) f32 {
        return switch (dimension) {
            .fit => |v| v.max,
            .fixed => |v| v.max,
            .grow => |v| v.max,
        };
    }

    pub fn unpackMin(dimension: Self) f32 {
        return switch (dimension) {
            .fit => |v| v.min,
            .fixed => |v| v.min,
            .grow => |v| v.min,
        };
    }
};

const Position = math.Vector2;

const Padding = struct {
    top: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,
};

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

    screenWidth: f32 = 0,
    screenHeight: f32 = 0,

    arena: std.heap.ArenaAllocator,
    growStack: std.ArrayList(*Box),
    drawStack: std.ArrayList(StackItem),

    root: ?Box,
    current: ?*Box,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .drawStack = .empty,
            .growStack = .empty,
            .current = null,
            .root = null,
        };
    }

    pub fn syncScreenSize(self: *Self, w: f32, h: f32) void {
        self.screenHeight = h;
        self.screenWidth = w;
    }

    pub fn beginLayout(self: *Self) void {
        self.reset();

        self.openScope(.init(.{
            .sizing = .{ .width = .{ .fixed = .{ .value = self.screenWidth } }, .height = .{ .fixed = .{ .value = self.screenHeight } } },
        }));
    }

    pub fn endLayout(self: *Self) void {
        self.closeScope();
        self.grow(true);
        self.grow(false);
        self.draw();
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
                        .grow => {},
                    }
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.height.fit.value = @max(parent.sizing.height.fit.value, h),
                        .fixed => {},
                        .grow => {},
                    }
                },
                .TopToBottom => {
                    switch (parent.sizing.height) {
                        .fit => parent.sizing.height.fit.value += h,
                        .fixed => {},
                        .grow => {},
                    }
                    switch (parent.sizing.width) {
                        .fit => parent.sizing.width.fit.value = @max(parent.sizing.width.fit.value, w),
                        .fixed => {},
                        .grow => {},
                    }
                },
            }

            self.current = parent;
        }
    }

    pub fn reset(self: *Self) void {
        _ = self.arena.reset(.retain_capacity);
        self.drawStack = .empty;
        self.growStack = .empty;
        self.root = null;
        self.current = null;
    }

    fn grow(self: *Self, xAxis: bool) void {
        if (self.root == null) return;

        self.drawStack.append(self.arena.allocator(), .{
            .box = &self.root.?,
            .elementPosition = self.root.?.position,
            .cursorPosition = .init(
                self.root.?.padding.left,
                self.root.?.padding.top,
            ),
        }) catch unreachable;

        self.growStack.clearRetainingCapacity();
        while (self.drawStack.items.len > 0) {
            const box = self.drawStack.pop().?.box;

            const sizingAlongAxis = (xAxis and box.layout == .LeftToRight) or (!xAxis and box.layout == .TopToBottom);
            const parentSize = if (xAxis) box.sizing.width.unpackDimension() else box.sizing.height.unpackDimension();
            const parentPadding: f32 = if (xAxis) (box.padding.left + box.padding.right) else (box.padding.top + box.padding.bottom);
            var innerContentSize: f32 = 0;
            var totalPaddingAndChildGaps: f32 = parentPadding;
            const parentGap: f32 = box.gap;
            var growContainerAmount: i32 = 0;

            // Calculate children bounds
            for (box.children.items, 0..box.children.items.len) |*child, index| {
                const childSizing = if (xAxis) child.sizing.width else child.sizing.height;

                if (childSizing == .grow) {
                    self.growStack.append(self.arena.allocator(), child) catch unreachable;
                    growContainerAmount += 1;
                }

                self.drawStack.append(self.arena.allocator(), .{ .box = child, .elementPosition = .empty, .cursorPosition = .empty }) catch unreachable;

                if (sizingAlongAxis) {
                    innerContentSize += childSizing.unpackDimension(); // or 0 when sizing is percent
                    if (index > 0) {
                        innerContentSize += parentGap;
                        totalPaddingAndChildGaps += parentGap;
                    }
                } else {
                    innerContentSize = @max(childSizing.unpackDimension(), innerContentSize);
                }
            }
            if (sizingAlongAxis) {
                var sizeToDistribute = parentSize - parentPadding - innerContentSize;
                // Children size is larger then element size. Shrink if possible;
                if (sizeToDistribute < 0) {} else if (growContainerAmount > 0) {
                    while (sizeToDistribute > 0.0001 and self.growStack.items.len > 0) {
                        var smallest: f32 = std.math.floatMax(f32);
                        var secondSmallest: f32 = smallest;
                        var widthToAdd = sizeToDistribute;

                        for (self.growStack.items) |growableElement| {
                            const childSizing = if (xAxis) growableElement.sizing.width.unpackDimension() else growableElement.sizing.height.unpackDimension();
                            if (std.math.approxEqAbs(f32, childSizing, smallest, 0.01)) continue;

                            if (childSizing < smallest) {
                                secondSmallest = smallest;
                                smallest = childSizing;
                            }
                            if (childSizing > smallest) {
                                secondSmallest = @min(secondSmallest, childSizing);
                                widthToAdd = secondSmallest - smallest;
                            }
                        }
                        widthToAdd = @min(widthToAdd, sizeToDistribute / @as(f32, @floatFromInt(self.growStack.items.len)));

                        var i: usize = 0;
                        while (i < self.growStack.items.len) {
                            const growableElement = self.growStack.items[i];
                            var childSizing = if (xAxis) &growableElement.sizing.width else &growableElement.sizing.height;
                            const maxSize = if (xAxis) growableElement.sizing.width.unpackMax() else growableElement.sizing.height.unpackMax();
                            const previousSize = childSizing.unpackDimension();

                            if (std.math.approxEqAbs(f32, childSizing.unpackDimension(), smallest, 0.01)) {
                                childSizing.* = childSizing.add(widthToAdd);
                                if (childSizing.unpackDimension() >= maxSize) {
                                    childSizing.* = childSizing.set(maxSize);
                                    // Remove this element from growth candidates
                                    _ = self.growStack.swapRemove(i);
                                    i -= 1; // Adjust index since we removed an item
                                }
                                sizeToDistribute -= (childSizing.unpackDimension() - previousSize);
                            }
                            i += 1;
                        }
                    }
                }
            } else {
                for (self.growStack.items) |growableElement| {
                    var childSizing = if (xAxis) &growableElement.sizing.width else &growableElement.sizing.height;
                    const minSize = if (xAxis) growableElement.sizing.width.unpackMin() else growableElement.sizing.height.unpackMin();
                    const maxSize = parentSize - parentPadding;

                    if (childSizing.* == .grow) {
                        childSizing.* = childSizing.set(@min(maxSize, childSizing.unpackMax()));
                    }
                    childSizing.* = childSizing.set(@max(minSize, @min(childSizing.unpackDimension(), maxSize)));
                }
            }
        }
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

            for (box.children.items) |*child| {
                const child_main = switch (box.layout) {
                    .LeftToRight => child.sizing.width.unpackDimension(),
                    .TopToBottom => child.sizing.height.unpackDimension(),
                };

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
            }
        }
    }
};
