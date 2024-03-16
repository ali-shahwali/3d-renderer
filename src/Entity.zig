const std = @import("std");
const math = @import("math.zig");

const Model = @import("Model.zig");
const Shader = @import("Shader.zig");

const Allocator = std.mem.Allocator;

const Entity = @This();

allocator: Allocator,
model: Model,
pos: math.Vec,
shader: *Shader,

pub fn init(allocator: Allocator, model: Model, shader: *Shader) Entity {
    return Entity{
        .allocator = allocator,
        .model = model,
        .shader = shader,
        .pos = math.f32x4(0, 0, 0, 1),
    };
}

pub fn deinit(self: *const Entity) void {
    self.model.deinit();
}

pub fn draw(self: *const Entity, projection: math.Mat, view: math.Mat) void {
    self.shader.use();

    self.shader.setMat4("projection", &projection);
    self.shader.setMat4("view", &view);
    self.shader.setMat4("model", &math.translationV(self.pos));

    self.model.draw(self.shader);
}
