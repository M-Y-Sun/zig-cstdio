# C `stdio` in Zig

A project that implements `stdio` functions from C's `stdio.h` header to Zig.

## Supported Functions[^1]

[^1]: Examples use `const cio = @import("cstdio.zig")` to import the package

#### `scanf`, `fscanf`

```zig
fscanf(stream: std.fs.File, comptime format: []const u8, args: anytype)
```

Both are implemented in `fscanf`; passing `std.io.getStdIn()` to `stream` will mimic `scanf` from `stdin`.

See the manpage for `fscanf` for format specifiers. Arguments are passed as a tuple of pointers.

##### Example

```zig
const parsed = try cio.fscanf(std.io.getStdIn(), "%u%lld%x%i%s", .{
    &uint,
    &int64,
    &hex,
    &infer_base,
    &str,
});
```

stdin:

```
4294967295 9223372036854775807 0xFFFFFFFF 07777777 foobar
```
