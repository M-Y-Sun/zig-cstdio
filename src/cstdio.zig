const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

fn readw(buf: []u8, reader: anytype) !usize {
    var i: usize = 0;
    var c: u8 = 0;

    while (i < buf.len) : (i += 1) {
        c = try reader.readByte();

        if (c == ' ' or c == '\n' or c == '\r')
            break;

        buf[i] = c;
    }

    return i;
}

fn totype(format: []const u8) type {
    _ = format;
    return i32;
    // for (format) |c| {
    //     switch (c) {}
    // }
}

pub fn c_fscanf(reader: anytype, format: []const u8, args: anytype) !usize {
    const args_type = @TypeOf(args);
    const args_type_info = @typeInfo(args_type);

    if (args_type_info != .Struct)
        @compileError("expected tuple or struct argument, found " ++ @typeName(args_type));

    const state_ = struct {
        var buf: [4096]u8 = undefined;
        var fbuf: [8]u8 = undefined;
        var flen: usize = 0;
    };

    var i: usize = 0;

    while (i < format.len and format[i] != '%') : (i += 1) {}

    inline for (&args) |*arg| {
        state_.flen = 0;
        i += 1;

        while (i < format.len and format[i] != '%') : (i += 1) {
            state_.fbuf[state_.flen] = format[i];
            state_.flen += 1;
        }

        const len = try readw(&state_.buf, reader);

        switch (@typeInfo(totype(&state_.fbuf))) {
            .Int => {
                arg.*.* = try std.fmt.parseInt(totype(&state_.fbuf), state_.buf[0..len], 10);
            },
            else => {},
        }
    }

    return 0;
}

pub fn main() !void {
    var n: i32 = 0;
    _ = try c_fscanf(stdin, "%d", .{&n});

    try stdout.print("{}\n", .{n});
}
