const std = @import("std");
const cio = @import("cstdio.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var isz: isize = undefined;
    var ldouble: f80 = undefined;
    var ll: i64 = undefined;
    var ushort: u16 = undefined;
    var hex8: u8 = undefined;
    var oct: u32 = undefined;
    var auto16: u16 = undefined;
    var str: []const u8 = "default";

    try stdout.print("{}, {}, {}, {}, {} (u8 hex), {} (u32 oct), {} (u16 auto), {}\n", .{
        @TypeOf(isz),
        @TypeOf(ldouble),
        @TypeOf(ll),
        @TypeOf(ushort),
        @TypeOf(hex8),
        @TypeOf(oct),
        @TypeOf(auto16),
        @TypeOf(str),
    });
    try bw.flush();

    _ = try cio.fscanf(std.io.getStdIn(), "%zd%Lf%lld%hu%hhx%o%hi%s", .{
        &isz,
        &ldouble,
        &ll,
        &ushort,
        &hex8,
        &oct,
        &auto16,
        &str,
    });

    try stdout.print("{}\n{}\n{}\n{}\n{}\n{}\n{}\n{s}\n", .{
        isz,
        ldouble,
        ll,
        ushort,
        hex8,
        oct,
        auto16,
        str,
    });
    try bw.flush();
}
