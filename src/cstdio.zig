const std = @import("std");

fn readw(buf: []u8, reader: anytype) !usize {
    var i: usize = 0;
    var c: u8 = 0;

    while (i < buf.len) : (i += 1) {
        c = try reader.readByte();

        if (c == ' ' or c == '\n' or c == '\r') {
            break;
        }

        buf[i] = c;
    }

    return i;
}

// TODO: Add hex and octal
fn totype(comptime format: []const u8) ?type {
    // parse int width prefix

    comptime var ibits: comptime_int = -1;
    comptime var lf = false;
    comptime var wchar = false;
    comptime var ptrtype = false;

    comptime var next: comptime_int = 1;

    switch (format[0]) {
        'h' => {
            ibits = 16;

            if (format.len > 1 and format[1] == 'h') {
                ibits >>= 1;
                next = 2;
            }
        },
        'l' => {
            ibits = 32;

            if (format.len > 1) {
                if (format[1] == 'l') {
                    ibits <<= 1;
                    next = 2;
                } else if (format[1] == 's' or format[1] == 'c') {
                    wchar = true;
                    ibits = -1;
                }
            }
        },
        'L' => {
            lf = true;
        },
        'j' => {
            ibits = 128;
        },
        't', 'z' => {
            ptrtype = true;
        },
        0 => {
            return null;
        },
        else => {
            next -= 1;
        },
    }

    if (next >= format.len) {
        return null;
    }

    // parse specifier

    const c = format[next];

    // TODO: implement 'i', 'o', and 'x'/'X'
    // TODO: implement %n to store number of characters
    switch (c) {
        'd', 'u' => {
            if (ptrtype) {
                return if (c == 'd') isize else usize;
            }

            switch (ibits) {
                8 => {
                    return if (c == 'd') i8 else u8;
                },
                16 => {
                    return if (c == 'd') i16 else u16;
                },
                32, -1 => {
                    return if (c == 'd') i32 else u32;
                },
                64 => {
                    return if (c == 'd') i64 else u64;
                },
                128 => {
                    return if (c == 'd') i128 else u128;
                },
                else => {
                    @compileError("invalid flag prefix, found " ++ ibits);
                },
            }
        },
        // TODO: implement strtod conversion
        'a', 'A', 'e', 'E', 'f', 'F', 'g', 'G' => {
            // return if (lf) f80 else f64;
            return f64; // parseFloat for f80 is not supported yet
        },
        's' => {
            return if (wchar) []const u32 else []const u8;
        },
        'S' => {
            return []const u32;
        },
        'c' => {
            return if (wchar) u32 else u8;
        },
        'C' => {
            return u32;
        },
        'p' => {
            return isize;
        },
        else => {
            @compileError("invalid format specifier, found " ++ c);
        },
    }
}

pub fn fscanf(reader: anytype, comptime format: []const u8, args: anytype) !usize {
    const args_type = @TypeOf(args);
    const args_type_info = @typeInfo(args_type);

    if (args_type_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(args_type));
    }

    var buf: [4096]u8 = undefined;
    comptime var fbuf: [8]u8 = undefined;
    comptime var flen: usize = 0;

    comptime var i: usize = 0;

    while (i < format.len and format[i] != '%') : (i += 1) {}

    var args_read: usize = 0;

    inline for (&args) |*arg| {
        flen = 0;
        i += 1;

        // TODO: deal with %%

        inline while (i < format.len and format[i] != '%') : (i += 1) {
            fbuf[flen] = format[i];
            flen += 1;
        }

        // maximum field width

        comptime var maxbytes: usize = 0;
        comptime var unspecified = true;

        while (fbuf[maxbytes] >= '0' and fbuf[maxbytes] <= '9') : (maxbytes += 1) {
            unspecified = false;
            if (maxbytes >= fbuf.len)
                return args_read;
        }

        // parse format specifier

        var len = try readw(&buf, reader);

        if (!unspecified)
            len = @min(len, maxbytes);

        const opt_fmt_t = totype(fbuf[0..flen]);

        if (opt_fmt_t == null)
            return args_read;

        const fmt_t = opt_fmt_t.?;

        arg.*.* = switch (@typeInfo(fmt_t)) {
            .Int => try std.fmt.parseInt(fmt_t, buf[0..len], 10),
            .Float => try std.fmt.parseFloat(fmt_t, buf[0..len]),
            .Pointer => buf[0..len],
            else => {
                @compileError("invalid type, found " ++ @typeName(fmt_t));
            },
        };

        args_read += 1;
    }

    return 0;
}
