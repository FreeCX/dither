const std = @import("std");
const Io = std.Io;

const image = @import("image.zig");
const util = @import("util.zig");

const log = std.log.scoped(.ppm);

// поддерживает только P3
pub fn readPixMapImage(gpa: std.mem.Allocator, io: Io, filename: []const u8) !image.PixMap {
    var buffer: [32]u8 = undefined;

    const file = try Io.Dir.cwd().openFile(io, filename, .{});
    defer file.close(io);
    var reader = file.reader(io, &buffer);
    const interface = &reader.interface;

    const format = try interface.take(2);
    log.debug("format: {s}", .{format});

    if (!std.mem.eql(u8, format, "P3")) {
        log.err("format {s} not supported", .{format});
        return error.UnsupportedFormat;
    }
    interface.toss(1);

    const width = try util.takeInt(u32, interface);
    const height = try util.takeInt(u32, interface);
    log.debug("size: {d}x{d}", .{ width, height });

    const maxval = try util.takeInt(u8, interface);
    log.debug("maxval: {d}", .{maxval});

    const data = try gpa.alloc(u8, width * height * 3);
    for (0..data.len) |index| {
        data[index] = try util.takeInt(u8, interface);
    }
    log.debug("bytes: {}", .{data.len});

    return image.PixMap{ .data = data, .width = width, .height = height };
}

// поддерживает только P3
pub fn writePixMapImage(io: Io, filename: []const u8, img: image.PixMap) !void {
    var buffer: [1024]u8 = undefined;

    const file = try Io.Dir.cwd().createFile(io, filename, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const interface = &writer.interface;

    try interface.print("P3\n{d} {d}\n255\n", .{ img.width, img.height });
    for (img.data) |value| {
        try interface.print("{d}\n", .{value});
    }
    try interface.flush();
}

// поддерживает только P1
pub fn writeBitMapImage(io: Io, filename: []const u8, img: image.BitMap) !void {
    var buffer: [1024]u8 = undefined;

    const file = try Io.Dir.cwd().createFile(io, filename, .{});
    defer file.close(io);
    var writer = file.writer(io, &buffer);
    const interface = &writer.interface;

    try interface.print("P1\n{d} {d}\n", .{ img.width, img.height });
    for (img.data) |set| {
        try interface.print("{d}\n", .{@as(u8, if (set) 1 else 0)});
    }
    try interface.flush();
}
