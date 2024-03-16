const std = @import("std");
const math = @import("math.zig");

const Camera = @This();

const MoveDirection = enum {
    forward,
    backward,
    left,
    right,
};

pos: math.Vec,
front: math.Vec,
up: math.Vec,
speed: f32,
_speed_vec: math.Vec,
yaw: f32,
pitch: f32,
sensitivity: f32,
zoom: f32,

pub fn init(init_pos: ?math.Vec) Camera {
    return Camera{
        .pos = if (init_pos) |pos| pos else math.f32x4(0, 2, 0, 1),
        .front = math.f32x4(0, 0, -1, 1),
        .up = math.f32x4(0, 1, 0, 1),
        .speed = 0.05,
        ._speed_vec = math.f32x4s(0.05),
        .yaw = 0,
        .pitch = 0,
        .sensitivity = 0.00001,
        .zoom = 45,
    };
}

pub fn getView(self: *const Camera) math.Mat {
    return math.lookAtRh(self.pos, self.pos + self.front, self.up);
}

pub fn setFront(self: *Camera, pos: math.Vec) void {
    self.front = pos;
}

pub fn setUp(self: *Camera, pos: math.Vec) void {
    self.up = pos;
}

pub fn setSpeed(self: *Camera, speed: f32) void {
    self.speed = speed;
    self._speed_vec = math.f32x4s(speed);
}

pub fn applyZoom(self: *Camera, zoom: f32) void {
    self.zoom -= zoom;
    if (self.zoom < 1) {
        self.zoom = 1;
    }
    if (self.zoom > 45) {
        self.zoom = 45;
    }
}

pub fn move(self: *Camera, dir: MoveDirection) void {
    switch (dir) {
        .forward => self.pos += self._speed_vec * self.front,
        .backward => self.pos -= self._speed_vec * self.front,
        .left => self.pos -= math.normalize4(math.cross3(self.front, self.up)) * self._speed_vec,
        .right => self.pos += math.normalize4(math.cross3(self.front, self.up)) * self._speed_vec,
    }
}

pub fn look(self: *Camera, x_offset: f32, y_offset: f32) void {
    self.yaw += x_offset * self.sensitivity;
    self.pitch += y_offset * self.sensitivity;

    if (self.pitch > 89) {
        self.pitch = 89;
    }
    if (self.pitch < -89) {
        self.pitch = -89;
    }

    const dir = math.f32x4(
        std.math.cos(math.deg2rad(self.yaw)) * std.math.cos(math.deg2rad(self.pitch)),
        std.math.sin(math.deg2rad(self.pitch)),
        std.math.sin(math.deg2rad(self.yaw)) * std.math.cos(math.deg2rad(self.pitch)),
        1,
    );

    self.setFront(math.normalize4(dir));
}
