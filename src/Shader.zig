const std = @import("std");
const gl = @import("opengl");
const math = @import("math.zig");

const Allocator = std.mem.Allocator;

const Shader = @This();

program_id: u32 = 0,
allocator: Allocator,
vs: ?u32,
fs: ?u32,
gs: ?u32,

pub fn init(allocator: Allocator) !Shader {
    return Shader{
        .allocator = allocator,
        .vs = undefined,
        .fs = undefined,
        .gs = undefined,
    };
}

pub fn addVertexShader(self: *Shader, comptime vert_path: []const u8) !void {
    const vertex_shader = readShader(vert_path);
    self.vs = try compile(vertex_shader, gl.VERTEX_SHADER, self.allocator);
}

pub fn addFragmentShader(self: *Shader, comptime frag_path: []const u8) !void {
    const fragment_shader = readShader(frag_path);
    self.fs = try compile(fragment_shader, gl.FRAGMENT_SHADER, self.allocator);
}

pub fn addGeometryShader(self: *Shader, comptime geom_path: []const u8) !void {
    const fragment_shader = readShader(geom_path);
    self.gs = try compile(fragment_shader, gl.GEOMETRY_SHADER, self.allocator);
}

pub fn create(self: *Shader) !void {
    self.program_id = gl.createProgram();

    if (self.vs) |vs| {
        gl.attachShader(self.program_id, vs);
    } else {
        @panic("ERROR: Creating shader without vertex shader");
    }

    if (self.fs) |fs| {
        gl.attachShader(self.program_id, fs);
    } else {
        @panic("ERROR: Creating shader without fragment shader");
    }

    defer gl.deleteShader(self.vs.?);
    defer gl.deleteShader(self.fs.?);

    if (self.gs) |gs| {
        gl.attachShader(self.program_id, gs);
    }

    gl.linkProgram(self.program_id);

    var ok: i32 = 0;
    gl.getProgramiv(self.program_id, gl.LINK_STATUS, &ok);
    if (ok == gl.FALSE) {
        defer gl.deleteProgram(self.program_id);

        var error_size: i32 = undefined;
        gl.getProgramiv(self.program_id, gl.INFO_LOG_LENGTH, &error_size);

        var message = try self.allocator.alloc(u8, @intCast(error_size));
        defer self.allocator.free(message);

        gl.getProgramInfoLog(self.program_id, error_size, &error_size, @as([*c]u8, @ptrCast(message)));
        std.debug.print("Error occured while linking shader program:\n\t{s}\n", .{message});
    }

    gl.validateProgram(self.program_id);

    if (self.gs) |gs| {
        gl.deleteShader(gs);
    }
}

pub fn deinit(self: *Shader) Shader {
    gl.deleteProgram(self.program_id);
    return Shader{
        .vs = undefined,
        .fs = undefined,
        .gs = undefined,
        .allocator = self.allocator,
    };
}

fn readShader(comptime path: []const u8) [*]const u8 {
    const content = @embedFile(path);

    return @ptrCast(content);
}

fn compile(source: [*]const u8, shader_type: c_uint, alloc: Allocator) !u32 {
    var result = gl.createShader(shader_type);
    gl.shaderSource(result, 1, &source, null);
    gl.compileShader(result);

    var whu: i32 = undefined;
    gl.getShaderiv(result, gl.COMPILE_STATUS, &whu);
    if (whu == gl.FALSE) {
        defer gl.deleteShader(result);

        var length: i32 = undefined;
        gl.getShaderiv(result, gl.INFO_LOG_LENGTH, &length);

        var message = try alloc.alloc(u8, @intCast(length));
        defer alloc.free(message);

        gl.getShaderInfoLog(result, length, &length, @ptrCast(message));

        const mtype =
            switch (shader_type) {
            gl.VERTEX_SHADER => "VERT",
            gl.FRAGMENT_SHADER => "FRAG",
            gl.GEOMETRY_SHADER => "GEOM",
            else => "UNDEFINED",
        };
        std.debug.print("Failed to compile shader(Type: {s})!\nError: {s}\n", .{
            mtype,
            message,
        });
    }
    return result;
}

pub fn getUniformLocation(self: *const Shader, name: []const u8) c_int {
    return gl.getUniformLocation(self.program_id, @ptrCast(name));
}

/// 0 for false, 1 for true
pub fn setBool(self: *const Shader, name: []const u8, value: c_int) void {
    const location = self.getUniformLocation(name);
    gl.uniform1i(location, value);
}

pub fn setFloat(self: *const Shader, name: []const u8, value: f32) void {
    const location = self.getUniformLocation(name);
    gl.uniform1f(location, value);
}

pub fn setMat4(self: *const Shader, name: []const u8, value: *const math.Mat) void {
    const location = self.getUniformLocation(name);
    gl.uniformMatrix4fv(location, 1, gl.FALSE, math.arrNPtr(value));
}

pub fn setVec3(self: *const Shader, name: []const u8, x: f32, y: f32, z: f32) void {
    const location = self.getUniformLocation(name);
    gl.uniform3f(location, x, y, z);
}

pub fn setVec3WithVec(self: *const Shader, name: []const u8, value: *const math.Vec) void {
    const location = self.getUniformLocation(name);
    gl.uniform3fv(location, 1, math.arr3Ptr(value));
}

pub fn setInt(self: *const Shader, name: []const u8, value: c_int) void {
    const location = self.getUniformLocation(name);
    gl.uniform1i(location, value);
}

pub fn use(self: *const Shader) void {
    gl.useProgram(self.program_id);
}
