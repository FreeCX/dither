const std = @import("std");

pub const Kernel = struct {
    data: []const u8,
    size: usize,

    pub fn value(self: Kernel, x: usize, y: usize) u8 {
        return self.data[(x % self.size) + self.size * (y % self.size)];
    }
};

pub const Kernel2x2 = Kernel{
    .data = &[_]u8{ 0, 128, 192, 64 },
    .size = 2,
};

pub const Kernel4x4 = Kernel{
    .data = &[_]u8{ 0, 128, 33, 161, 192, 64, 225, 97, 49, 177, 15, 143, 241, 113, 207, 79 },
    .size = 4,
};

pub fn shuffleKernel(gpa: std.mem.Allocator, base: Kernel, random: std.Random) !Kernel {
    const shuffled = Kernel{
        .data = try gpa.dupe(u8, base.data),
        .size = base.size,
    };
    random.shuffle(u8, @constCast(shuffled.data));
    return shuffled;
}
