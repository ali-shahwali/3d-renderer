const std = @import("std");
const Model = @import("Model.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Scene = @This();

models: ArrayList(*Model),
allocator: Allocator,

pub fn init(allocator: Allocator) Scene {
    return Scene{
        .allocator = allocator,
        .models = ArrayList(*Model),
    };
}

pub fn addModel(self: *Scene, model: *Model) !void {
    try self.models.append(model);
}

pub fn draw(self: *const Scene) void {
    for (self.models.items) |model| {
        _ = model;
    }
}
