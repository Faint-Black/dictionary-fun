const std = @import("std");

timer: std.time.Timer = undefined,
name: []const u8 = "UNDEFINED",

pub fn begin(job_name: []const u8) @This() {
    var result = @This(){};
    result.name = job_name;
    result.timer = std.time.Timer.start() catch {
        @panic("Failed to begin benchmark!");
    };
    return result;
}

pub fn end(self: *@This()) void {
    const nanoseconds = self.timer.read();
    const formatted_time = std.fmt.fmtDuration(nanoseconds);
    std.debug.print("Job \"{s}\" done in {s}.\n", .{ self.name, formatted_time });
}
