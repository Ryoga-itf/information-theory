const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const max_size = std.math.maxInt(u8);

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
        \\ TODO
    ;

    const result = calculateFrequencies(text, struct {
        fn f(char: u8) bool {
            return char != '\n' and char != ' ';
        }
    }.f);

    try stdout.print("length: {d}\n", .{result.length});

    for (result.frequencies, result.probabilities, 0..) |freq, prob, char| {
        if (freq > 0) {
            try stdout.print("| '{c}' | {d: >6} | {d}\n", .{ @as(u8, @intCast(char)), freq, prob });
        }
    }

    try stdout.print("entropy: {d}\n", .{calculateEntropy(result.probabilities)});

    var tree = HuffmanTree.init(allocator, result.frequencies);
    defer tree.deinit();

    try tree.build();

    var iter = tree.Iterator();
    while (iter.next()) |c| {
        std.debug.print("{c}\n", .{c});
    }

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

const HuffmanTree = struct {
    const Self = @This();
    const Key = u8;

    pub const Node = struct {
        @"0": ?Key = null,
        @"1": ?*Node = null,
    };

    arena: ArenaAllocator,
    frequencies: [max_size]usize,
    root: ?*Node = null,

    pub fn init(allocator: Allocator, frequencies: [max_size]usize) Self {
        return Self{
            .arena = ArenaAllocator.init(allocator),
            .frequencies = frequencies,
            .root = null,
        };
    }

    pub fn deinit(tree: Self) void {
        tree.arena.deinit();
    }

    pub fn build(tree: *Self) !void {
        const allocator = tree.arena.allocator();
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

        tree.root = try allocator.create(Node);
        var current = tree.root.?;
        current.@"0" = null;
        current.@"1" = null;

        for (tree.frequencies, 0..) |freq, char| {
            if (freq > 0) {
                try queue.add(Item{
                    .key = @intCast(char),
                    .freq = freq,
                });
            }
        }

        while (queue.removeOrNull()) |top| {
            current.@"0" = top.key;
            current.@"1" = try allocator.create(Node);
            current = current.@"1".?;
        }
    }

    pub fn Iterator(tree: *Self) struct {
        const Iter = @This();
        current: ?*Node = null,

        fn next(self: *Iter) ?u8 {
            if (self.current) |cur| {
                defer self.current = cur.@"1";
                return cur.@"0";
            } else {
                return null;
            }
        }
    } {
        return .{
            .current = tree.root,
        };
    }
};
