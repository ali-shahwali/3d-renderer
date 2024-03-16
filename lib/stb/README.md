# Zig bindings for stb

Raw bindings generated with `zig translate-c` for stb.

To use it in your project, put the code somewhere in your project, `lib/stb` for example, then add the following to your `build.zig`.

```rust
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});

exe.addCSourceFile(.{
        .file = .{ .path = "lib/stb/c/stb_image.c" },
        .flags = &.{
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });

exe.addModule("stb", b.createModule(.{
    .source_file = .{ .path = "lib/stb/stb.zig" },
}));
...
```