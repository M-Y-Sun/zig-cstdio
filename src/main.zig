const std = @import("std");
const cio = @import("cstdio.zig");

pub fn main() !void {
    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var usz: usize = undefined;
    var ldouble: f80 = undefined;
    var ll: i64 = undefined;
    var ushort: u16 = undefined;
    var str: []const u8 = "default";
    _ = try cio.fscanf(stdin, "%zd%Lf%lld%hu%s", .{ &usz, &ldouble, &ll, &ushort, &str });

    try stdout.print("{}\n{}\n{}\n{}\n{s}\n", .{ usz, ldouble, ll, ushort, str });

    try bw.flush();
}
