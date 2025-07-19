const std = @import("std");
const Benchmark = @import("benchmark.zig");
const stdout = std.io.getStdOut().writer();

pub const Entry = struct {
    string: []u8,
    hash: u64,

    pub fn deinit(self: Entry, allocator: std.mem.Allocator) void {
        allocator.free(self.string);
    }

    pub fn print(self: Entry) void {
        stdout.print("[Hash = 0x{X:0>16}, ", .{self.hash}) catch unreachable;
        stdout.print("String = \"{s}\"]\n", .{self.string}) catch unreachable;
    }

    pub fn predAlphabetical(context: void, a: Entry, b: Entry) bool {
        _ = context;
        return switch (std.mem.order(u8, a.string, b.string)) {
            .lt => true,
            .eq => false,
            .gt => false,
        };
    }

    pub fn predHash(context: void, a: Entry, b: Entry) bool {
        _ = context;
        return (a.hash <= b.hash);
    }
};

pub const EntryList = struct {
    allocator: std.mem.Allocator,
    entries: []Entry,

    const filesize_limit = 1073741824;

    pub fn init(allocator: std.mem.Allocator, filename: []const u8) !EntryList {
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        const file_contents = try file.reader().readAllAlloc(allocator, filesize_limit);
        defer allocator.free(file_contents);

        var result: EntryList = undefined;
        result = try parseDictionary(allocator, file_contents);
        result.ascendingHash();
        if (result.hasHashCollision()) return error.HashCollisionOccured;
        return result;
    }

    /// free each allocated string
    pub fn deinit(self: EntryList) void {
        for (self.entries) |entry| {
            entry.deinit(self.allocator);
        }
    }

    /// 64-bit FNV-1a algorithm
    pub fn hashFromBytes(bytes: []const u8) u64 {
        const offset_basis: u64 = 14695981039346656037;
        const large_prime: u64 = 1099511628211;
        var hash: u64 = offset_basis;
        for (bytes) |byte| {
            hash ^= byte;
            hash *%= large_prime;
        }
        return hash;
    }

    /// parsing helper
    fn isWordSeparator(character: u8) bool {
        return (character == '\n' or character == ' ' or character == '\r');
    }

    /// print one entry
    pub fn printEntry(self: EntryList, index: usize) void {
        self.entries[index].print();
    }

    /// print all entries
    pub fn printEntries(self: EntryList) void {
        for (self.entries) |entry| {
            entry.print();
        }
    }

    /// [file contents] => [entries]
    fn parseDictionary(allocator: std.mem.Allocator, contents: []const u8) !EntryList {
        var character_vector = std.ArrayList(u8).init(allocator);
        defer character_vector.deinit();
        var entry_vector = std.ArrayList(Entry).init(allocator);
        defer entry_vector.deinit();

        for (contents) |c| {
            if (isWordSeparator(c)) {
                if (character_vector.items.len != 0) {
                    const built_string = try character_vector.toOwnedSlice();
                    const new_entry = Entry{
                        .string = built_string,
                        .hash = hashFromBytes(built_string),
                    };
                    try entry_vector.append(new_entry);
                }
                continue;
            }
            try character_vector.append(c);
        }

        return EntryList{
            .allocator = allocator,
            .entries = try entry_vector.toOwnedSlice(),
        };
    }

    /// ascending sort of hashes
    fn ascendingHash(self: EntryList) void {
        var timer = Benchmark.begin("SORT HASHES");
        defer timer.end();
        std.mem.sortUnstable(Entry, self.entries, {}, Entry.predHash);
    }

    /// returns true if a hash collision on the sorted list exists
    fn hasHashCollision(self: EntryList) bool {
        var timer = Benchmark.begin("CHECK HASH COLLISIONS");
        defer timer.end();
        for (1..self.entries.len) |i| {
            const l = self.entries[i - 1].hash;
            const r = self.entries[i].hash;
            if (l == r) return true;
        }
        return false;
    }
};
