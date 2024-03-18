const std = @import("std");
const gl = @import("opengl");
const stb = @import("stb");
const Shader = @import("Shader.zig");
const math = @import("math.zig");
const util = @import("util.zig");
const zmesh = @import("zmesh");

const addressToVoidPtr = util.addressToVoidPtr;
const thisDir = util.thisDir;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Mesh = @This();

const Vertex = struct {
    pos: [3]f32,
    norm: [3]f32,
    texcoords: [2]f32,
};

const Texture = struct {
    id: u32,
    type: []const u8,
    path: []const u8,
};

allocator: Allocator,
VAO: c_uint = undefined,
VBO: c_uint = undefined,
EBO: c_uint = undefined,
indices: std.ArrayList(u32),
vertices: std.ArrayList(Vertex),

pub fn init(allocator: Allocator) Mesh {
    return Mesh{
        .allocator = allocator,
        .indices = std.ArrayList(u32).init(allocator),
        .vertices = std.ArrayList(Vertex).init(allocator),
    };
}

pub fn deinit(self: *const Mesh) void {
    self.indices.deinit();
    self.vertices.deinit();
}

fn setupMesh(self: *Mesh) void {
    gl.genVertexArrays(1, &self.VAO);
    gl.genBuffers(1, &self.VBO);
    gl.genBuffers(1, &self.EBO);

    gl.bindVertexArray(self.VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, self.VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @as(isize, @intCast(self.vertices.items.len)) * @sizeOf(Vertex), @ptrCast(&self.vertices.items[0]), gl.STATIC_DRAW);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @as(isize, @intCast(self.indices.items.len)) * @sizeOf(u32), @ptrCast(&self.indices.items[0]), gl.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), addressToVoidPtr(@offsetOf(Vertex, "pos")));

    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), addressToVoidPtr(@offsetOf(Vertex, "norm")));

    gl.enableVertexAttribArray(2);
    gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), addressToVoidPtr(@offsetOf(Vertex, "texcoords")));

    gl.bindVertexArray(0);
}

fn printVertices(self: *const Mesh) void {
    std.debug.print("\n", .{});

    for (self.vertices.items) |v| {
        std.debug.print("Pos: x<{d}> y<{d}> z<{d}> \t", .{ v.pos[0], v.pos[1], v.pos[2] });
        std.debug.print("Norm: x<{d}> y<{d}> z<{d}> \t", .{ v.norm[0], v.norm[1], v.norm[2] });
        std.debug.print("Texcoord: u<{d}> u<{d}> \n", .{ v.texcoords[0], v.texcoords[1] });
    }
}

fn printIndices(self: *const Mesh) void {
    std.debug.print("\n", .{});

    for (self.indices.items) |v| {
        std.debug.print("{d} ", .{v});
    }

    std.debug.print("\n", .{});
}

pub fn loadFromModel(self: *Mesh, model: *zmesh.io.zcgltf.Data, mesh_index: u32) !void {
    var positions = std.ArrayList([3]f32).init(self.allocator);
    var normals = std.ArrayList([3]f32).init(self.allocator);
    var texcoords = std.ArrayList([2]f32).init(self.allocator);
    defer positions.deinit();
    defer normals.deinit();
    defer texcoords.deinit();

    try zmesh.io.appendMeshPrimitive(
        model, // *zmesh.io.cgltf.Data
        mesh_index, // mesh index
        0, // gltf primitive index (submesh index)
        &self.indices,
        &positions,
        &normals, // normals (optional)
        &texcoords, // texcoords (optional)
        null, // tangents (optional)
    );

    for (positions.items, normals.items, texcoords.items) |pos, norm, uv| {
        try self.vertices.append(Vertex{
            .pos = pos,
            .norm = norm,
            .texcoords = uv,
        });
    }

    self.setupMesh();
}

pub fn draw(self: *const Mesh, shader: *Shader) void {
    _ = shader;

    gl.bindVertexArray(self.VAO);
    gl.drawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, addressToVoidPtr(0));
    gl.bindVertexArray(0);
}
