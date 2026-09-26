const std = @import("std");

const ppm = @import("ppm.zig");
const dithering = @import("dithering.zig");
const kernel = @import("kernel.zig");

const log = std.log.scoped(.app);

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 3) {
        log.info("usage: {s} <input.ppm> <output.ppm>", .{args[0]});
        return;
    }

    var random = std.Random.Xoroshiro128.init(42);
    const shuffled = try kernel.shuffleKernel(arena, kernel.Kernel4x4, random.random());
    defer arena.free(shuffled.data);

    const image = try ppm.readPixMapImage(arena, io, args[1]);
    defer image.deinit(arena);
    var bitmap = try dithering.process(arena, shuffled, image);
    defer bitmap.deinit(arena);
    try ppm.writeBitMapImage(io, args[2], bitmap);
}

test {
    std.testing.refAllDecls(@This());
}
