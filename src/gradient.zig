const std = @import("std");

const image = @import("image.zig");

fn generateGradient(gpa: std.mem.Allocator) !image.PixMap {
    const size: usize = 256;
    const total = size * size * 3;

    const data = try gpa.alloc(u8, total);

    var index: usize = 0;
    while (index < total) : (index += 3) {
        const y = @as(u8, @intCast(index / (3 * size)));
        data[index + 0] = y;
        data[index + 1] = y;
        data[index + 2] = y;
    }

    return image.PixMap{ .data = data, .width = size, .height = size };
}
