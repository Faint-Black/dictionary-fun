const std = @import("std");
const EntryList = @import("parse.zig").EntryList;
const Benchmark = @import("benchmark.zig");

/// binary search through hashes
/// returns null on fail
pub fn search(list: EntryList, string: []const u8) ?usize {
    var timer = Benchmark.begin("BINARY SEARCH");
    defer timer.end();

    const hash = EntryList.hashFromBytes(string);
    var lo: usize = 0;
    var hi: usize = list.entries.len - 1;
    while (lo <= hi) {
        const mid: usize = lo + ((hi - lo) / 2);
        if (list.entries[mid].hash == hash) {
            return mid;
        }
        if (list.entries[mid].hash < hash) {
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return null;
}
