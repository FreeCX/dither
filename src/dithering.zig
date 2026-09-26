const std = @import("std");

const image = @import("image.zig");
const Kernel = @import("kernel.zig").Kernel;

const log = std.log.scoped(.dithering);

pub fn process(gpa: std.mem.Allocator, kernel: Kernel, img: image.PixMap) !image.BitMap {
    const data = try gpa.alloc(bool, img.width * img.height);

    // TODO: подумать над параллельной обработкой
    var index: usize = 0;
    while (index < img.width * img.height * 3) : (index += 3) {
        const pos = (index / 3);
        const threshold = kernel.value(pos % img.width, pos / img.width);
        const value = img.data[index];
        data[pos] = value < threshold;
    }

    return image.BitMap{ .data = data, .width = img.width, .height = img.height };
}
