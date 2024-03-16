const std = @import("std");

pub fn addressToVoidPtr(address: usize) *allowzero const anyopaque {
    return @as(*allowzero const anyopaque, @ptrFromInt(address));
}

pub fn thisDir(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

pub fn readM3dFile(comptime relative_path: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    const model_file = try std.fs.cwd().openFile(thisDir(relative_path), .{});
    defer model_file.close();

    const model_data = try model_file.readToEndAllocOptions(allocator, 1024, 119, @alignOf(u8), 0);
    return model_data;
}
