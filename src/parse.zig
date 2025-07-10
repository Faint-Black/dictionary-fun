const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

/// separate monolithic arrays, for better caching
pub const EntryList = struct {
    allocator: std.mem.Allocator,
    string_list: [][]u8,
    hash_list: []u64,

    pub fn init(allocator: std.mem.Allocator) EntryList {
        return EntryList{
            .allocator = allocator,
            .string_list = undefined,
            .hash_list = undefined,
        };
    }

    /// each backend string is allocated, this frees them
    pub fn deinit(self: EntryList) void {
        for (self.string_list) |string| {
            self.allocator.free(string);
        }
        self.allocator.free(self.string_list);
        self.allocator.free(self.hash_list);
    }

    pub fn printEntries(self: EntryList) void {
        for (self.string_list, self.hash_list) |string, hash| {
            stderr.print("Hash = 0x{X:0>16}, ", .{hash}) catch unreachable;
            stderr.print("String = \"{s}\"\n", .{string}) catch unreachable;
        }
    }

    pub fn parse(self: *EntryList, contents: []const u8) !void {
        var character_vector = std.ArrayList(u8).init(self.allocator);
        defer character_vector.deinit();
        var string_vector = std.ArrayList([]u8).init(self.allocator);
        defer string_vector.deinit();
        var hash_vector = std.ArrayList(u64).init(self.allocator);
        defer hash_vector.deinit();

        var i: usize = 0;
        var c: u8 = 0;
        while (i < 100) : (i += 1) {
            c = contents[i];
            if (isWordSeparator(c)) {
                const built_string = try character_vector.toOwnedSlice();
                try string_vector.append(built_string);
                try hash_vector.append(hashFromBytes(built_string));
                continue;
            }
            try character_vector.append(c);
        }

        self.string_list = try string_vector.toOwnedSlice();
        self.hash_list = try hash_vector.toOwnedSlice();
    }
};

/// 64-bit FNV-1a algorithm
pub fn hashFromBytes(bytes: []u8) u64 {
    const offset_basis: u64 = 14695981039346656037;
    const large_prime: u64 = 1099511628211;
    var hash: u64 = offset_basis;
    for (bytes) |byte| {
        hash ^= byte;
        hash *%= large_prime;
    }
    return hash;
}

/// [file] => [entries]
pub fn parseFile(filename: []const u8, allocator: std.mem.Allocator) !void {
    const gigabyte = 1073741824;
    const file = try std.fs.cwd().openFile(filename, .{});
    const file_contents = try file.reader().readAllAlloc(allocator, gigabyte);
    defer allocator.free(file_contents);

    var entry_list = EntryList.init(allocator);
    defer entry_list.deinit();
    try entry_list.parse(file_contents);
    entry_list.printEntries();
}

fn isWordSeparator(character: u8) bool {
    return (character == '\n' or character == ' ');
}
