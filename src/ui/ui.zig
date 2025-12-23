// src/ui/ui.zig
const std = @import("std");
const rl = @import("raylib");

pub const LayoutDirection = enum {
    LEFT_TO_RIGHT,
    TOP_TO_BOTTOM,
};

pub const UIElement = struct {
    id: []const u8,
    layout: LayoutDirection,
    position: ?rl.Vector2,
    dimension: ?rl.Vector2,
    backgroundColor: rl.Color,

    onClick: ?*const fn () void,
    onHover: ?*const fn () void,
    children: std.ArrayList([]u8),

    pub fn init(allocator: std.mem.Allocator, config: anytype) !UIElement {
        var children = try std.ArrayList([]u8).initCapacity(allocator, 0);
        if (@hasField(@TypeOf(config), "children")) {
            for (config.children) |child| {
                try children.append(allocator, try allocator.dupe(u8, child));
            }
        }

        return .{
            .id = config.id,
            .backgroundColor = config.backgroundColor,
            .layout = if (@hasField(@TypeOf(config), "layout")) config.layout else .LEFT_TO_RIGHT,
            .position = if (@hasField(@TypeOf(config), "position")) config.position else null,
            .dimension = if (@hasField(@TypeOf(config), "dimension")) config.dimension else null,
            .onClick = if (@hasField(@TypeOf(config), "onClick")) config.onClick else null,
            .onHover = if (@hasField(@TypeOf(config), "onHover")) config.onHover else null,
            .children = children,
        };
    }

    pub fn deinit(self: *UIElement, allocator: std.mem.Allocator) void {
        for (self.children.items) |child| {
            allocator.free(child);
        }
        self.children.deinit(allocator);
    }
};

pub const Context = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    elements: std.StringHashMap(UIElement),
    parent_stack: std.ArrayList([]u8),

    pub fn init() Self {
        const allocator = std.heap.page_allocator;
        return .{
            .allocator = allocator,
            .elements = std.StringHashMap(UIElement).init(allocator),
            .parent_stack = std.ArrayList([]u8).initCapacity(allocator, 0) catch unreachable,
        };
    }

    pub fn deinit(self: *Self) void {
        var it = self.elements.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
        }
        self.elements.deinit();
        self.parent_stack.deinit(self.allocator);
    }

    pub fn beginElement(self: *Self, config: anytype) !void {
        const id = config.id;
        const element = try UIElement.init(self.allocator, config);

        // If there's a current parent, add this as child
        if (self.parent_stack.items.len > 0) {
            const parent_id = self.parent_stack.items[self.parent_stack.items.len - 1];
            if (self.elements.getPtr(parent_id)) |parent| {
                try parent.children.append(self.allocator, try self.allocator.dupe(u8, id));
            }
        }

        try self.elements.put(try self.allocator.dupe(u8, id), element);
        try self.parent_stack.append(self.allocator, try self.allocator.dupe(u8, id));
    }

    pub fn endElement(self: *Self) void {
        _ = self.parent_stack.pop();
    }

    pub fn clear(self: *Self) void {
        var it = self.elements.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.children.items) |child| {
                self.allocator.free(child);
            }
            entry.value_ptr.children.clearRetainingCapacity();
        }
        self.elements.clearRetainingCapacity();
        self.parent_stack.clearRetainingCapacity();
    }

    pub fn render(self: *Self) void {
        // Start from root elements (those not in any parent's children)
        var it = self.elements.iterator();
        while (it.next()) |entry| {
            const element = entry.value_ptr;
            if (!self.isChildOfAny(element.id)) {
                self.renderElement(element, .{ .x = 0, .y = 0 });
            }
        }
    }

    fn isChildOfAny(self: *Self, id: []const u8) bool {
        var it = self.elements.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.children.items) |child_id| {
                if (std.mem.eql(u8, child_id, id)) return true;
            }
        }
        return false;
    }

    fn renderElement(self: *Self, element: *const UIElement, parent_pos: rl.Vector2) void {
        const pos = if (element.position) |p| rl.Vector2{ .x = parent_pos.x + p.x, .y = parent_pos.y + p.y } else parent_pos;
        const size = element.dimension orelse rl.Vector2{ .x = 100, .y = 100 }; // default size

        // Create bounds rectangle for input checking
        const bounds = rl.Rectangle{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };

        var isHover = false;
        // Handle input during render
        const mousePos = rl.getMousePosition();
        if (rl.checkCollisionPointRec(mousePos, bounds)) {
            isHover = true;
            if (rl.isMouseButtonPressed(.left)) {
                if (element.onClick) |callback| {
                    callback();
                }
            }
            if (element.onHover) |callback| {
                callback();
            }
        }
        const color = if (isHover) rl.Color.alpha(element.backgroundColor, 0.7) else element.backgroundColor;
        rl.drawRectangle(@intFromFloat(pos.x), @intFromFloat(pos.y), @intFromFloat(size.x), @intFromFloat(size.y), color);

        // Calculate child positions based on layout
        var current_pos = pos;
        for (element.children.items) |child_id| {
            if (self.elements.getPtr(child_id)) |child| {
                self.renderElement(child, current_pos);
                // Update position for next child
                if (element.layout == .LEFT_TO_RIGHT) {
                    current_pos.x += child.dimension.?.x;
                } else {
                    current_pos.y += child.dimension.?.y;
                }
            }
        }
    }
};
