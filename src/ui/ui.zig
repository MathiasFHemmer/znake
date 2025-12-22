// src/ui/ui.zig
const std = @import("std");
const rl = @import("raylib");

pub const Frame = struct {
    backgroundColor: rl.Color,
    layout: LayoutDirection,
    width: ?f32,
    height: ?f32,
    onClick: ?*const fn (data: *anyopaque) void,
    onHover: ?*const fn (data: *anyopaque) void,
    elements: []UIElementConfig,

    pub fn init(config: anytype) Frame {
        return .{
            .backgroundColor = config.backgroundColor,
            .layout = config.layout,
            .width = if (@hasField(@TypeOf(config), "width")) config.width else null,
            .height = if (@hasField(@TypeOf(config), "height")) config.height else null,
            .onClick = if (@hasField(@TypeOf(config), "onClick")) config.onClick else null,
            .onHover = if (@hasField(@TypeOf(config), "onHover")) config.onHover else null,
            .elements = config.elements,
        };
    }
};

pub const Button = struct {
    color: rl.Color,
    width: f32,
    height: f32,
    onClick: ?*const fn (data: *anyopaque) void,
    onHover: ?*const fn (data: *anyopaque) void,

    pub fn init(config: anytype) Button {
        return .{
            .color = config.color,
            .width = config.width,
            .height = config.height,
            .onClick = if (@hasField(@TypeOf(config), "onClick")) config.onClick else null,
            .onHover = if (@hasField(@TypeOf(config), "onHover")) config.onHover else null,
        };
    }
};

pub const UIElementConfig = union(enum) {
    frame: Frame,
    button: Button,
};

pub const UIConfig = struct {
    data: *anyopaque,
    layout: LayoutDirection,
    elements: []UIElementConfig,
};

pub const ButtonResult = struct {
    clicked: bool,
    hovered: bool,
};

pub const Context = struct {
    const Self = @This();
    mousePosition: rl.Vector2,
    canvaSize: rl.Vector2,
    selectPressed: bool,
    root: UIElement,
    currentParent: *UIElement,
    container: UIElement,
    previousParent: ?*UIElement,

    pub fn init() Self {
        return .{
            .mousePosition = .zero(),
            .canvaSize = .zero(),
            .selectPressed = false,
            .root = UIElement.init(),
            .currentParent = undefined,
            .container = UIElement.init(),
            .previousParent = null,
        };
    }

    pub fn beginDraw(self: *Self) void {
        self.mousePosition = rl.getMousePosition();
        self.canvaSize = .init(@floatFromInt(rl.getScreenWidth()), @floatFromInt(rl.getScreenHeight()));
        self.selectPressed = rl.isMouseButtonPressed(rl.MouseButton.left);
        self.root = UIElement{
            .position = .init(0, 0),
            .dimension = self.canvaSize,
            .backgroundColor = rl.Color.white,
            .layoutDirection = .LEFT_TO_RIGHT,
            .currentLayoutPosition = .init(0, 0),
        };
        self.currentParent = &self.root;
        self.previousParent = null;
    }

    pub fn endDraw(self: *Self) void {
        self.selectPressed = false;
    }
};

pub const LayoutDirection = enum {
    LEFT_TO_RIGHT,
    TOP_TO_BOTTOM,
    CENTERED,
};

pub const UIElement = struct {
    const Self = @This();

    position: rl.Vector2,
    dimension: rl.Vector2,
    backgroundColor: rl.Color,
    layoutDirection: LayoutDirection,
    currentLayoutPosition: rl.Vector2,

    pub fn init() Self {
        return Self{
            .position = .init(0, 0),
            .dimension = .init(0, 0),
            .backgroundColor = rl.Color.white,
            .layoutDirection = .LEFT_TO_RIGHT,
            .currentLayoutPosition = .init(0, 0),
        };
    }
};

pub fn beginContainer(width: f32, height: f32, backgroundColor: rl.Color, layoutDirection: LayoutDirection, ctx: *Context) void {
    ctx.container = UIElement{
        .position = if (layoutDirection == .CENTERED) ctx.currentParent.position.add(ctx.currentParent.dimension.sub(.init(width, height)).scale(0.5)) else ctx.currentParent.position.add(ctx.currentParent.currentLayoutPosition),
        .dimension = .init(width, height),
        .backgroundColor = backgroundColor,
        .layoutDirection = layoutDirection,
        .currentLayoutPosition = .init(0, 0),
    };
    rl.drawRectangleRec(.init(ctx.container.position.x, ctx.container.position.y, width, height), backgroundColor);
    ctx.previousParent = ctx.currentParent;
    ctx.currentParent = &ctx.container;
}

pub fn endContainer(ctx: *Context) void {
    ctx.currentParent = ctx.previousParent.?;
    ctx.previousParent = null;
}

pub fn DrawButton(width: f32, height: f32, buttonColor: rl.Color, ctx: *Context) bool {
    var result = false;
    var color = rl.colorAlpha(buttonColor, 0.7);
    var posX: f32 = undefined;
    var posY: f32 = undefined;

    if (ctx.currentParent.layoutDirection == .CENTERED) {
        posX = ctx.currentParent.position.x + (ctx.currentParent.dimension.x - width) / 2;
        posY = ctx.currentParent.position.y + (ctx.currentParent.dimension.y - height) / 2;
    } else {
        posX = ctx.currentParent.position.x + ctx.currentParent.currentLayoutPosition.x;
        posY = ctx.currentParent.position.y + ctx.currentParent.currentLayoutPosition.y;
        if (ctx.currentParent.layoutDirection == .LEFT_TO_RIGHT) {
            ctx.currentParent.currentLayoutPosition.x += width;
        } else if (ctx.currentParent.layoutDirection == .TOP_TO_BOTTOM) {
            ctx.currentParent.currentLayoutPosition.y += height;
        }
    }

    const rec = rl.Rectangle.init(posX, posY, width, height);
    if (CheckCollisionPointRec(ctx.mousePosition, rec)) {
        color = rl.colorAlpha(buttonColor, 1);
        result = ctx.selectPressed;
    }
    rl.drawRectangleRec(rec, color);
    return result;
}

fn CheckCollisionPointRec(point: rl.Vector2, rec: rl.Rectangle) bool {
    const insideX = (point.x >= rec.x) and (point.x <= (rec.x + rec.width));
    const insideY = (point.y >= rec.y) and (point.y <= (rec.y + rec.height));
    return insideX and insideY;
}
