const std = @import("std");
const Io = std.Io;
const Iterator = std.process.Args.Iterator;

const appname = @import("app_info").name;
const kernel = @import("kernel.zig");

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

const Parsed = struct {
    input: []const u8,
    output: []const u8,
    kernel: kernel.Kernel,
};

fn parseKernelType(value: []const u8) KernelType {
    if (std.mem.eql(u8, value, "2x2")) return .Kernel2x2;
    if (std.mem.eql(u8, value, "4x4")) return .Kernel4x4;
    if (std.mem.eql(u8, value, "any")) return .KernelAny;
    if (std.mem.eql(u8, value, "shuffle")) return .KernelShuffle;
    return .Unknown;
}

fn parseArgsKernelAny(gpa: std.mem.Allocator, args: *Iterator, stdout: *Io.Writer) !?kernel.Kernel {
    const size_arg = args.next();
    if (size_arg == null) {
        try stdout.print(usageKernelAny, .{appname});
        try stdout.flush();
        return null;
    }
    const size = try std.fmt.parseInt(u8, size_arg.?, 10);
    return try kernel.kernelAny(gpa, size);
}

fn parseArgsKernelShuffle(gpa: std.mem.Allocator, args: *Iterator, stdout: *Io.Writer) !?kernel.Kernel {
    const size_arg = args.next();
    const seed_arg = args.next();
    if (size_arg == null or seed_arg == null) {
        try stdout.print(usageKernelShuffle, .{appname});
        try stdout.flush();
        return null;
    }

    const size = try std.fmt.parseInt(u8, size_arg.?, 10);
    const seed = try std.fmt.parseInt(u64, seed_arg.?, 10);
    const anykernel = try kernel.kernelAny(gpa, size);

    var random = std.Random.Xoroshiro128.init(seed);
    return try kernel.shuffleKernel(gpa, anykernel, random.random());
}

pub fn parseArgs(gpa: std.mem.Allocator, args: *Iterator, stdout: *Io.Writer) !?Parsed {
    const kernel_type = args.next();
    if (kernel_type == null) {
        try stdout.print(usageBase, .{appname});
        return null;
    }

    const work_kernel = switch (parseKernelType(kernel_type.?)) {
        .Kernel2x2 => kernel.Kernel2x2,
        .Kernel4x4 => kernel.Kernel4x4,
        .KernelAny => try parseArgsKernelAny(gpa, args, stdout),
        .KernelShuffle => try parseArgsKernelShuffle(gpa, args, stdout),
        .Unknown => {
            try stdout.print(usageBase, .{appname});
            try stdout.flush();
            return null;
        },
    };
    if (work_kernel == null) return null;

    const input_arg = args.next();
    const output_arg = args.next();
    if (input_arg == null or output_arg == null) {
        try stdout.print(usageBase, .{appname});
        try stdout.flush();
        return null;
    }

    return Parsed{
        .input = input_arg.?,
        .output = output_arg.?,
        .kernel = work_kernel.?,
    };
}
