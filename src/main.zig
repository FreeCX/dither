const std = @import("std");
const Io = std.Io;

const ppm = @import("ppm.zig");
const dither = @import("dither.zig");
const args = @import("args.zig");

pub fn main(init: std.process.Init) !void {
    // arena сама всё почистит
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var arguments = try init.minimal.args.iterateAllocator(arena);
    _ = arguments.skip();

    const parsed = try args.parseArgs(arena, &arguments, stdout);
    if (parsed == null) return;

    const image = try ppm.readPixMapImage(arena, io, parsed.?.input);
    const bitmap = try dither.process(arena, parsed.?.kernel, image);
    try ppm.writeBitMapImage(io, parsed.?.output, bitmap);
}

test {
    std.testing.refAllDecls(@This());
}
