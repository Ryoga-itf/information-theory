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

    var tree = HuffmanTree.init(allocator, result.frequencies, result.probabilities);
    defer tree.deinit();

    try tree.build();

    var code = try tree.generateCode(allocator);
    defer code.deinit();

    for (0..max_size) |char| {
        if (code.map.get(@intCast(char))) |c| {
            try stdout.print("| '{c}' | {s} \n", .{ @as(u8, @intCast(char)), c });
        }
    }

    try stdout.print("Average Huffman code length: {d} bits per character.\n", .{code.averageCodeLength(result.probabilities)});

    try stdout.print("Original size: {d} bits\n", .{char_size * result.length});
    try stdout.print("Compressed size: {d} bits\n", .{size: {
        var sum: usize = 0;
        for (0..max_size) |char| {
            if (code.map.get(@intCast(char))) |c| {
                sum += c.len * result.frequencies[char];
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

const HuffmanTree = struct {
    const Tree = @This();
    const Key = u8;

    pub const Node = struct {
        char: ?u8 = null,
        freq: usize,
        @"0": ?*Node = null,
        @"1": ?*Node = null,
    };

    arena: ArenaAllocator,
    frequencies: [max_size]usize,
    probabilities: [max_size]f128,
    root: ?*Node = null,

    pub fn init(allocator: Allocator, frequencies: [max_size]usize, probabilities: [max_size]f128) Tree {
        return Tree{
            .arena = ArenaAllocator.init(allocator),
            .frequencies = frequencies,
            .probabilities = probabilities,
        };
    }

    pub fn deinit(tree: *Tree) void {
        tree.arena.deinit();
    }

    pub fn build(tree: *Tree) !void {
        const allocator = tree.arena.allocator();
        const MinHeap = std.PriorityQueue(*Node, void, struct {
            fn lessThan(_: void, a: *Node, b: *Node) std.math.Order {
                return std.math.order(a.freq, b.freq);
            }
        }.lessThan);
        var queue = MinHeap.init(allocator, {});
        defer queue.deinit();

        for (tree.frequencies, 0..) |freq, char| {
            if (freq > 0) {
                var node = try allocator.create(Node);
                node.char = @intCast(char);
                node.freq = freq;
                try queue.add(node);
            }
        }

        while (queue.count() > 1) {
            const @"0" = queue.remove();
            const @"1" = queue.remove();

            var merged = try allocator.create(Node);
            merged.char = null;
            merged.freq = @"0".freq + @"1".freq;
            merged.@"0" = @"0";
            merged.@"1" = @"1";

            try queue.add(merged);
        }

        if (queue.removeOrNull()) |root| {
            tree.root = root;
        }
    }

    pub const Code = struct {
        const Self = @This();
        const Map = std.AutoHashMap(Key, []u8);

        arena: ArenaAllocator,
        map: Map,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .arena = ArenaAllocator.init(allocator),
                .map = Map.init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
            self.arena.deinit();
        }

        pub fn averageCodeLength(self: *Self, probabilities: [max_size]f128) f128 {
            var average: f128 = 0;
            for (0..max_size) |char| {
                if (self.map.get(@intCast(char))) |code| {
                    average += @as(f128, @floatFromInt(code.len)) * probabilities[char];
                }
            }
            return average;
        }
    };

    pub fn generateCode(tree: Tree, allocator: Allocator) !Code {
        var code = Code.init(allocator);
        errdefer code.deinit();

        if (tree.root) |root| {
            var list = std.ArrayList(u8).init(allocator);
            defer list.deinit();
            try generateCodeRec(&code, root, &list);
        }

        return code;
    }

    fn generateCodeRec(code: *Code, current: *Node, list: *std.ArrayList(u8)) !void {
        const allocator = code.arena.allocator();
        if (current.char) |char| {
            try code.map.put(char, try allocator.dupe(u8, list.items));
            return;
        }
        if (current.@"0") |@"0"| {
            try list.append('0');
            try generateCodeRec(code, @"0", list);
            _ = list.pop();
        }
        if (current.@"1") |@"1"| {
            try list.append('1');
            try generateCodeRec(code, @"1", list);
            _ = list.pop();
        }
    }
};
