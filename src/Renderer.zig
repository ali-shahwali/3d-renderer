const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("opengl");
const math = @import("math.zig");
const WINSIZE = @import("window.zig").WINSIZE;

const Camera = @import("Camera.zig");
// const Entity = @import("Entity.zig");
// const Scene = @import("Scene.zig");
const Shader = @import("Shader.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Renderer = @This();

delta_time: f32,
last_frame: f32,
UBO_matrices: u32 = undefined,

pub fn init() Renderer {
    return Renderer{
        .delta_time = 0,
        .last_frame = 0,
    };
}

pub fn deinit(self: *const Renderer) void {
    _ = self;
}

fn processInput(self: *Renderer, window: *const glfw.Window, camera: *Camera) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }

    if (window.getKey(glfw.Key.left_shift) == glfw.Action.press) {
        camera.setSpeed(10 * self.delta_time);
    } else {
        camera.setSpeed(2.5 * self.delta_time);
    }

    if (window.getKey(glfw.Key.w) == glfw.Action.press) {
        camera.move(.forward);
    }

    if (window.getKey(glfw.Key.s) == glfw.Action.press) {
        camera.move(.backward);
    }

    if (window.getKey(glfw.Key.a) == glfw.Action.press) {
        camera.move(.left);
    }

    if (window.getKey(glfw.Key.d) == glfw.Action.press) {
        camera.move(.right);
    }
}

pub fn configureUBO(self: *Renderer, shaders: ArrayList(*Shader)) void {
    for (shaders.items) |shader| {
        const block_idx = gl.getUniformBlockIndex(shader.program_id, "ViewProjection");
        gl.uniformBlockBinding(shader.program_id, block_idx, 0);
    }

    gl.genBuffers(1, &self.UBO_matrices);
    gl.bindBuffer(gl.UNIFORM_BUFFER, self.UBO_matrices);
    gl.bufferData(gl.UNIFORM_BUFFER, 2 * @sizeOf(math.Mat), null, gl.STATIC_DRAW);
    gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
    gl.bindBufferRange(gl.UNIFORM_BUFFER, 0, self.UBO_matrices, 0, 2 * @sizeOf(math.Mat));
}

pub fn renderScene(self: *Renderer, camera: *Camera, window: *const glfw.Window) void {
    const current_frame: f32 = @floatCast(glfw.getTime());
    self.delta_time = current_frame - self.last_frame;
    self.last_frame = current_frame;

    self.processInput(window, camera);

    const size = window.getFramebufferSize();
    gl.viewport(0, 0, @intCast(size.width), @intCast(size.height));

    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    const projection = math.perspectiveFovRhGl(math.deg2rad(camera.zoom), WINSIZE[0] / WINSIZE[1], 0.1, 300);
    const view = camera.getView();

    gl.bindBuffer(gl.UNIFORM_BUFFER, self.UBO_matrices);
    gl.bufferSubData(gl.UNIFORM_BUFFER, 0, @sizeOf(math.Mat), math.arrNPtr(&view));
    gl.bufferSubData(gl.UNIFORM_BUFFER, @sizeOf(math.Mat), @sizeOf(math.Mat), math.arrNPtr(&projection));
    gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
}
