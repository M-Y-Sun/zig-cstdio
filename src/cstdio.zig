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

const fmtspec_t = struct {
    ftype: type = void,
    base: u8 = 10,
    len: ?usize = null, // TODO: implement
};

// TODO: Add hex and octal
fn totype(comptime format: []const u8) ?fmtspec_t {
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

    comptime var ret: fmtspec_t = .{};
    const c = format[next];

    // TODO: implement 'i', 'o', and 'x'/'X'
    // TODO: implement %n to store number of characters
    // TODO: add format specifier for binary (doesnt exist in scanf) and throw compiler warning
    switch (c) {
        'd', 'u', 'i', 'o', 'x', 'X' => blk: {
            if (ptrtype) {
                ret.ftype = if (c == 'd') isize else usize;
                break :blk;
            }

            ret.base = switch (c) {
                'i' => 0, // auto-detect base
                'o' => 8,
                'x', 'X' => 16,
                else => 10,
            };

            ret.ftype = switch (ibits) {
                8 => if (c == 'd') i8 else u8,
                16 => if (c == 'd') i16 else u16,
                32, -1 => if (c == 'd') i32 else u32,
                64 => if (c == 'd') i64 else u64,
                128 => if (c == 'd') i128 else u128,
                else => {
                    @compileError("invalid flag prefix, found " ++ ibits);
                },
            };
        },
        // TODO: implement strtod conversion
        'a', 'A', 'e', 'E', 'f', 'F', 'g', 'G' => {
            // return if (lf) f80 else f64;
            ret.ftype = f64; // parseFloat for f80 is not supported yet
        },
        's' => {
            ret.ftype = if (wchar) []const u32 else []const u8;
        },
        'S' => {
            ret.ftype = []const u32;
        },
        'c' => {
            ret.ftype = if (wchar) u32 else u8;
        },
        'C' => {
            ret.ftype = u32;
        },
        'p' => {
            ret.ftype = isize;
        },
        else => {
            @compileError("invalid format specifier, found " ++ c);
        },
    }

    return ret;
}

pub fn fscanf(stream: std.fs.File, comptime format: []const u8, args: anytype) !usize {
    var bw = std.io.bufferedReader(stream.reader());
    const reader = bw.reader();

    const args_type = @TypeOf(args);

    if (@typeInfo(args_type) != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(args_type));
    }

    const state_ = struct {
        var buf: [4096]u8 = undefined;
    };

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

        var len = try readw(&state_.buf, reader);

        if (!unspecified)
            len = @min(len, maxbytes);

        const opt_fmt_t = totype(fbuf[0..flen]);

        if (opt_fmt_t == null)
            return args_read;

        const fmt_ftype = opt_fmt_t.?.ftype;
        var fmt_base = opt_fmt_t.?.base;
        // const fmt_len = opt_fmt_t.?.len;

        const start: usize = switch (fmt_base) {
            0 => blk: {
                if ((len >= 2 and state_.buf[0] == '0' and state_.buf[1] != 'x') or (len == 1 and state_.buf[0] == '0')) {
                    fmt_base = 8;
                    break :blk 1;
                } else {
                    break :blk 0;
                }
            },
            8 => if (len >= 1 and state_.buf[0] == '0') 1 else 0,
            16 => if (len >= 2 and state_.buf[0] == '0' and (state_.buf[1] == 'x' or state_.buf[1] == 'X')) 2 else 0,
            else => 0,
        };

        arg.*.* = switch (@typeInfo(fmt_ftype)) {
            .Int => try std.fmt.parseInt(fmt_ftype, state_.buf[start..len], fmt_base),
            .Float => try std.fmt.parseFloat(fmt_ftype, state_.buf[0..len]),
            .Pointer => state_.buf[0..len],
            else => {
                @compileError("invalid type, found " ++ @typeName(fmt_ftype));
            },
        };

        args_read += 1;
    }

    return 0;
}
