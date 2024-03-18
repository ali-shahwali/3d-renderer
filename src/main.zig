const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("opengl");
const math = @import("math.zig");
const zmesh = @import("zmesh");

const thisDir = @import("util.zig").thisDir;
const readM3dFile = @import("util.zig").readM3dFile;
const createWindow = @import("window.zig").createWindow;

const Camera = @import("Camera.zig");
const Shader = @import("Shader.zig");
const Model = @import("Model.zig");
const Renderer = @import("Renderer.zig");

const WINSIZE = [2]u32{ 1440, 1080 };

const DEBUG = false;

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

const Mouse = struct {
    x: f32,
    y: f32,
};

var mouse = Mouse{ .x = 0, .y = 0 };
var camera = Camera.init(math.f32x4(55, 12, 3, 90));
var delta_time: f32 = 0;
var last_frame: f32 = 0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    zmesh.init(allocator);

    // Cleanup
    defer {
        zmesh.deinit();
        glfw.terminate();

        const check = gpa.deinit();
        if (check == .leak) {
            @panic("Memory leak detected.");
        }
    }

    const window = try createWindow(WINSIZE[0], WINSIZE[1], "OpenGL + GLFW + stb + Zig");
    defer window.destroy();

    glfw.makeContextCurrent(window);
    window.setInputMode(glfw.Window.InputMode.cursor, glfw.Window.InputModeCursor.disabled);
    window.setCursorPosCallback(mouseCallback);
    window.setScrollCallback(scrollCallback);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    gl.enable(gl.DEPTH_TEST);

    // MSAA
    gl.enable(gl.MULTISAMPLE);

    // Backface culling
    gl.enable(gl.CULL_FACE);
    gl.cullFace(gl.BACK);
    gl.frontFace(gl.CCW);

    glfw.swapInterval(1);

    var cube = Model.init(allocator);
    defer cube.deinit();
    try cube.loadGLTF("./src/meshes/mountain.glb");

    var light = Model.init(allocator);
    defer light.deinit();
    try light.loadGLTF("./src/meshes/cube.glb");

    var shader = try Shader.init(allocator);
    try shader.addVertexShader("./shaders/blinn_phong.vs");
    try shader.addFragmentShader("./shaders/blinn_phong.fs");
    try shader.create();
    defer shader = shader.deinit();

    var light_shader = try Shader.init(allocator);
    try light_shader.addVertexShader("./shaders/light_cube.vs");
    try light_shader.addFragmentShader("./shaders/light_cube.fs");
    try light_shader.create();
    defer light_shader = light_shader.deinit();

    var shaders = std.ArrayList(*Shader).init(allocator);
    defer shaders.deinit();

    try shaders.append(&shader);
    try shaders.append(&light_shader);

    var renderer = Renderer.init();
    renderer.configureUBO(shaders);

    if (DEBUG) {
        gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);
    }

    const light_pos = math.f32x4(2, 2, 1.2, 1);
    const model = math.scaling(50, 50, 50);
    var light_model = math.scaling(0.2, 0.2, 0.2);
    light_model = math.mul(math.mul(math.translation(0, 10, 0), model), light_model);
    light_model = math.mul(math.scaling(0.2, 0.2, 0.2), light_model);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        defer window.swapBuffers();
        defer glfw.pollEvents();

        renderer.renderScene(&camera, &window);

        shader.use();

        shader.setMat4("model", &model);
        shader.setVec3("objectColor", 1.0, 0.5, 0.31);
        shader.setVec3WithVec("light.position", &light_pos);
        shader.setVec3WithVec("viewPos", &camera.pos);
        shader.setVec3("light.ambient", 0.2, 0.3, 0.1);
        shader.setVec3("light.diffuse", 0.1, 0.5, 0.2);
        shader.setVec3("light.specular", 1.0, 1.0, 1.0);
        shader.setVec3("material.ambient", 1.0, 0.5, 0.31);
        shader.setVec3("material.diffuse", 1.0, 0.5, 0.31);
        shader.setVec3("material.specular", 0.5, 0.5, 0.5);
        shader.setFloat("material.shininess", 1.0);

        cube.draw(&shader);

        light_shader.use();

        light_shader.setMat4("model", &light_model);

        light.draw(&light_shader);
    }
}

fn mouseCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    _ = window;

    const x_pos: f32 = @floatCast(xpos);
    const y_pos: f32 = @floatCast(ypos);

    const x_offset = x_pos - mouse.x;
    const y_offset = mouse.y - y_pos;
    mouse.x = x_pos;
    mouse.y = y_pos;

    camera.look(x_offset, y_offset);
}

fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = window;
    _ = xoffset;

    camera.applyZoom(@floatCast(yoffset * 0.001));
}
