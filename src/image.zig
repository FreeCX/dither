const std = @import("std");

pub fn Image(comptime T: type) type {
    return struct {
        data: []T,
        width: u32,
        height: u32,

        pub fn deinit(self: @This(), gpa: std.mem.Allocator) void {
            gpa.free(self.data);
        }
    };
}

pub const BitMap = Image(bool);
pub const PixMap = Image(u8);
