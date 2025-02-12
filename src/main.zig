const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const max_size = std.math.maxInt(u8);
const char_size = @typeInfo(u8).Int.bits;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // if (args.len < 2) {
    //     std.debug.print("Usage: {s} <file>\n", .{args[0]});
    //     std.posix.exit(1);
    // }

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const text =
        \\In the beginning God created the heavens and the earth. Now the earth was formless and empty, 
        \\darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.
    ;

    const filter = struct {
        fn f(char: u8) bool {
            return char != '\n' and char != ' ';
        }
    }.f;

    const result = calculateFrequencies(text, filter);

    try stdout.print("length: {d}\n", .{result.length});

    for (result.frequencies, result.probabilities, 0..) |freq, prob, char| {
        if (freq > 0) {
            try stdout.print("| '{c}' | {d: >6} | {d}\n", .{ @as(u8, @intCast(char)), freq, prob });
        }
    }

    try stdout.print("entropy: {d}\n", .{calculateEntropy(result.probabilities)});

    var map = HuffmanCodeMap.init(allocator, result.frequencies, result.probabilities);
    defer map.deinit();

    try map.build();

    for (0..max_size) |char| {
        if (map.item.get(@intCast(char))) |code| {
            try stdout.print("| '{c}' | {s} \n", .{ @as(u8, @intCast(char)), code });
        }
    }

    try stdout.print("Average Huffman code length: {d} bits per character.\n", .{map.averageCodeLength()});

    try stdout.print("Original size: {d} bits\n", .{char_size * result.length});
    try stdout.print("Compressed size: {d} bits\n", .{size: {
        var sum: usize = 0;
        for (0..max_size) |char| {
            if (map.item.get(@intCast(char))) |code| {
                sum += code.len * result.frequencies[char];
            }
        }
        break :size sum;
    }});

    try bw.flush();
}

/// Calculate character frequencies and probabilities
fn calculateFrequencies(text: []const u8, filter: fn (u8) bool) struct {
    frequencies: [max_size]usize,
    probabilities: [max_size]f128,
    length: usize,
} {
    var frequencies = [_]usize{0} ** max_size;
    var probabilities = [_]f128{0} ** max_size;
    var length: usize = 0;

    for (text) |char| {
        if (filter(char)) {
            frequencies[char] += 1;
            length += 1;
        }
    }

    for (frequencies, 0..) |freq, char| {
        if (freq > 0) {
            probabilities[char] = @as(f128, @floatFromInt(freq)) / @as(f128, @floatFromInt(length));
        }
    }

    return .{
        .frequencies = frequencies,
        .probabilities = probabilities,
        .length = length,
    };
}

/// Calculate entropy
fn calculateEntropy(probabilities: [max_size]f128) f128 {
    var entropy: f128 = 0;
    for (probabilities) |prob| {
        if (prob > 0) {
            entropy += -prob * @log2(prob);
        }
    }
    return entropy;
}

const HuffmanCodeMap = struct {
    const Map = @This();
    const Key = u8;

    arena: ArenaAllocator,
    frequencies: [max_size]usize,
    probabilities: [max_size]f128,
    item: std.AutoHashMap(Key, []u8),

    pub fn init(allocator: Allocator, frequencies: [max_size]usize, probabilities: [max_size]f128) Map {
        return Map{
            .arena = ArenaAllocator.init(allocator),
            .frequencies = frequencies,
            .probabilities = probabilities,
            .item = std.AutoHashMap(Key, []u8).init(allocator),
        };
    }

    pub fn deinit(self: *Map) void {
        self.item.deinit();
        self.arena.deinit();
    }

    pub fn build(self: *Map) !void {
        const allocator = self.arena.allocator();
        const Item = struct {
            key: Key,
            freq: usize,
        };
        const MaxHeap = std.PriorityQueue(Item, void, struct {
            fn greaterThan(_: void, a: Item, b: Item) std.math.Order {
                return std.math.order(a.freq, b.freq).invert();
            }
        }.greaterThan);

        var queue = MaxHeap.init(allocator, {});
        defer queue.deinit();

        for (self.frequencies, 0..) |freq, char| {
            if (freq > 0) {
                try queue.add(Item{
                    .key = @intCast(char),
                    .freq = freq,
                });
            }
        }

        var length: usize = 1;
        var code = try allocator.alloc(u8, length);

        while (queue.removeOrNull()) |top| {
            switch (queue.count()) {
                0 => {
                    try self.item.put(top.key, code);
                },
                else => {
                    code[length - 1] = '0';
                    try self.item.put(top.key, code);
                    if (queue.count() > 1) {
                        length += 1;
                    }
                    code = try allocator.alloc(u8, length);
                    @memset(code, '1');
                },
            }
        }
    }

    pub fn averageCodeLength(self: Map) f128 {
        var average: f128 = 0;
        for (0..max_size) |char| {
            if (self.item.get(@intCast(char))) |code| {
                average += @as(f128, @floatFromInt(code.len)) * self.probabilities[char];
            }
        }
        return average;
    }
};
