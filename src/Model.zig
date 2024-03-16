const std = @import("std");
const math = @import("math.zig");
const zmesh = @import("zmesh");
const Mesh = @import("Mesh.zig");
const Shader = @import("Shader.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Model = @This();

allocator: Allocator,
meshes: ArrayList(Mesh),
model: *zmesh.io.zcgltf.Data = undefined,

pub fn init(allocator: Allocator) Model {
    return Model{
        .allocator = allocator,
        .meshes = ArrayList(Mesh).init(allocator),
    };
}

pub fn deinit(self: *const Model) void {
    defer self.meshes.deinit();

    for (self.meshes.items) |mesh| {
        mesh.deinit();
    }

    zmesh.io.freeData(self.model);
}

pub fn loadGLTF(self: *Model, comptime path: [:0]const u8) !void {
    self.model = try zmesh.io.parseAndLoadFile(path);

    if (self.model.meshes) |_| {
        for (0..self.model.meshes_count) |i| {
            var mesh = Mesh.init(self.allocator);
            try mesh.loadFromModel(self.model, @intCast(i));
            try self.meshes.append(mesh);
        }
    } else unreachable;
}

pub fn draw(self: *const Model, shader: *Shader) void {
    for (self.meshes.items) |mesh| {
        mesh.draw(shader);
    }
}
