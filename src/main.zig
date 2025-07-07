const std = @import("std");
const builtin = @import("builtin");

const release_version_string = switch (builtin.mode) {
    .Debug => "DEBUG",
    .ReleaseFast => "FAST",
    .ReleaseSafe => "SAFE",
    .ReleaseSmall => "SMALL",
};

pub fn main() void {
    // set up allocator
    // var gpa = std.heap.DebugAllocator(.{}).init;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    var timer = std.time.Timer.start() catch {
        std.debug.print("Failed to start timer!\n", .{});
        return;
    };

    const cores = std.Thread.getCpuCount() catch {
        std.debug.print("Failed to get CPU cores!\n", .{});
        return;
    };

    std.debug.print("CPU cores: {}\n", .{cores});
    std.debug.print("Release version: {s}\n", .{release_version_string});

    const nanoseconds = timer.read();
    const time = std.fmt.fmtDuration(nanoseconds);
    std.debug.print("Done in {s}\n", .{time});
}
