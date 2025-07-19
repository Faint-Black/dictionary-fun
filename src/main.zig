const std = @import("std");
const builtin = @import("builtin");
const parse = @import("parse.zig");
const Benchmark = @import("benchmark.zig");
const algo = @import("algorithms.zig");

const byte = 1;
const kilobyte = 1024 * byte;
const megabyte = 1024 * kilobyte;
const gigabyte = 1024 * megabyte;

const release_version_string = switch (builtin.mode) {
    .Debug => "DEBUG",
    .ReleaseFast => "FAST",
    .ReleaseSafe => "SAFE",
    .ReleaseSmall => "SMALL",
};

pub fn main() void {
    // begin benchmark
    var timer = Benchmark.begin("MAIN");
    defer timer.end();

    // set up allocator
    // fixed buffer allocator only allocates/deallocates once
    // fastest solution for this kind of problem
    const preallocation = 1 * gigabyte;
    const pager = std.heap.page_allocator;
    const heap_buffer = pager.alloc(u8, gigabyte) catch {
        std.debug.print("Failed to allocate {} bytes!\n", .{preallocation});
        return;
    };
    defer pager.free(heap_buffer);
    var fba = std.heap.FixedBufferAllocator.init(heap_buffer);
    const allocator = fba.allocator();

    const filename = getArg(allocator) catch {
        std.debug.print("Failed to parse command-line arguments!\n", .{});
        return;
    };
    const cores = std.Thread.getCpuCount() catch {
        std.debug.print("Failed to get CPU cores!\n", .{});
        return;
    };
    std.debug.print("Cores: {}\n", .{cores});
    std.debug.print("Version: {s}\n", .{release_version_string});
    std.debug.print("Filename: \"{s}\"\n", .{filename});
    std.debug.print("Pre-allocation: 0x{X} bytes\n", .{preallocation});

    const entries = parse.EntryList.init(allocator, filename) catch |err| {
        std.debug.print("Failed to parse file: \"{s}\"\n", .{@errorName(err)});
        return;
    };
    defer entries.deinit();

    const binary_search_query = algo.search(entries, "aardvark");
    if (binary_search_query) |query| {
        std.debug.print("searched for word \"aardvark\": ", .{});
        entries.printEntry(query);
    }
}

/// get provided filename for the dictionary
fn getArg(allocator: std.mem.Allocator) ![]const u8 {
    var argv = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argv.deinit();
    if (argv.skip() == false) return error.HowDidThisHappen;
    const arg = argv.next() orelse "undefined";
    return arg;
}
