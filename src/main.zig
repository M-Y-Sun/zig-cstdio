const std = @import("std");
const cio = @import("cstdio.zig");

pub fn main() !void {
    const stdin_file = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_file);
    const stdin = br.reader();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var n: i32 = 0;
    var m: i32 = 0;
    _ = try cio.fscanf(stdin, "%d%d", .{ &n, &m });

    try stdout.print("{} {}\n", .{ n, m });

    try bw.flush();
}
