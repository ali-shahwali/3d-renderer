const zmath = @import("zmath");
pub usingnamespace zmath;

pub inline fn deg2rad(deg: f32) f32 {
    return deg / 0.0174532925199432957;
}

pub fn flatFaceNorm(p1: zmath.Vec, p2: zmath.Vec, p3: zmath.Vec) zmath.Vec {
    const v1 = p1 - p2;
    const v2 = p1 - p3;
    const cross = zmath.cross3(v2, v1);
    return zmath.normalize3(cross);
}
