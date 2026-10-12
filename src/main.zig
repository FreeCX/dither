const std = @import("std");
const Io = std.Io;

const ppm = @import("ppm.zig");
const dither = @import("dither.zig");
const kernel = @import("kernel.zig");
const appname = @import("app_info").name;

const log = std.log.scoped(.app);

const usageBase =
    \\usage: {s} <kernel> [kernel-arguments] <input> <output>
    \\
    \\Support kernels:
    \\  2x2
    \\  4x4
    \\  any
    \\  shuffle
    \\
    \\Arguments:
    \\  input  -- input ppm file
    \\  output -- output ppm file
    \\
;
const usageKernelAny =
    \\usage: {s} any <kernel-size> <input> <output>
    \\
    \\Kernel arguments:
    \\  kernel-size -- [2, 15]
    \\
;
const usageKernelShuffle =
    \\usage: {s} shuffle <kernel-size> <random-seed> <input> <output>
    \\
    \\Kernel arguments:
    \\  kernel-size -- [2, 15]
    \\  random-seed -- [0, 18446744073709551615]
    \\
;

const KernelType = enum {
    Kernel2x2,
    Kernel4x4,
    KernelAny,
    KernelShuffle,
    Unknown,
};

fn parseKernelType(value: []const u8) KernelType {
    if (std.mem.eql(u8, value, "2x2")) return .Kernel2x2;
    if (std.mem.eql(u8, value, "4x4")) return .Kernel4x4;
    if (std.mem.eql(u8, value, "any")) return .KernelAny;
    if (std.mem.eql(u8, value, "shuffle")) return .KernelShuffle;
    return .Unknown;
}

pub fn main(init: std.process.Init) !void {
    // arena сама всё почистит
    const arena: std.mem.Allocator = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var args = try init.minimal.args.iterateAllocator(arena);
    _ = args.skip();

    const kernel_type = args.next();
    if (kernel_type == null) {
        try stdout.print(usageBase, .{appname});
        return;
    }

    const work_kernel = switch (parseKernelType(kernel_type.?)) {
        .Kernel2x2 => kernel.Kernel2x2,
        .Kernel4x4 => kernel.Kernel4x4,
        .KernelAny => kernel: {
            const size_arg = args.next();
            if (size_arg == null) {
                try stdout.print(usageKernelAny, .{appname});
                return;
            }
            const size = try std.fmt.parseInt(u8, size_arg.?, 10);
            break :kernel try kernel.kernelAny(arena, size);
        },
        .KernelShuffle => kernel: {
            const size_arg = args.next();
            const seed_arg = args.next();
            if (size_arg == null or seed_arg == null) {
                try stdout.print(usageKernelShuffle, .{appname});
                return;
            }

            const size = try std.fmt.parseInt(u8, size_arg.?, 10);
            const seed = try std.fmt.parseInt(u64, seed_arg.?, 10);
            const anykernel = try kernel.kernelAny(arena, size);

            var random = std.Random.Xoroshiro128.init(seed);
            break :kernel try kernel.shuffleKernel(arena, anykernel, random.random());
        },
        .Unknown => {
            try stdout.print(usageBase, .{appname});
            return;
        },
    };

    const input_arg = args.next();
    const output_arg = args.next();
    if (input_arg == null or output_arg == null) {
        try stdout.print(usageBase, .{appname});
        return;
    }

    const image = try ppm.readPixMapImage(arena, io, input_arg.?);
    const bitmap = try dither.process(arena, work_kernel, image);
    try ppm.writeBitMapImage(io, output_arg.?, bitmap);
}

test {
    std.testing.refAllDecls(@This());
}
