const std = @import("std");
const Io = std.Io;

fn takeUntilAny(reader: *Io.Reader, delimiters: []const u8) ![]u8 {
    var count: usize = 1;

    while (true) {
        const item = reader.peek(count) catch |err| switch (err) {
            error.EndOfStream => {
                if (count > 1) {
                    return try reader.take(count - 1);
                }
                return error.EndOfStream;
            },
            else => return err,
        };
        const last = item[item.len - 1];
        if (std.mem.findScalar(u8, delimiters, last) != null) {
            reader.toss(count);
            return item[0 .. item.len - 1];
        }
        count += 1;
    }
}

pub fn takeInt(comptime T: type, reader: *Io.Reader) !T {
    const value = try takeUntilAny(reader, " \n\t");
    return try std.fmt.parseInt(T, value, 10);
}

test "read values until delimiter" {
    const string_values = [_][]const u8{ "1", "20", "300", "42", "5" };
    const int_values = [_]u16{ 1, 20, 300, 42, 5 };
    const data = "1 20\n300\t42\n5";
    var reader = Io.Reader.fixed(data);

    for (string_values) |expected| {
        const actual = try takeUntilAny(&reader, " \n\t");
        try std.testing.expectEqualStrings(expected, actual);
    }

    reader.seek = 0;

    for (int_values) |expected| {
        const actual = try takeInt(u16, &reader);
        try std.testing.expectEqual(expected, actual);
    }
}

test "read until delimiter failed with EndOfStream" {
    var reader = Io.Reader.fixed("");

    try std.testing.expectEqual(
        error.EndOfStream,
        takeUntilAny(&reader, " "),
    );
}

test "read only one value without delimiter" {
    var reader = Io.Reader.fixed("42");
    try std.testing.expectEqual(42, takeInt(u16, &reader));
}
