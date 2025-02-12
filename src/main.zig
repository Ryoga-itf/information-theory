const std = @import("std");

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

    try bw.flush();
}

/// Calculate character frequencies and probabilities
fn calculateFrequencies(text: []const u8, filter: fn (u8) bool) struct {
    frequencies: [256]usize,
    probabilities: [256]f128,
    length: usize,
} {
    var frequencies = [_]usize{0} ** 256;
    var probabilities = [_]f128{0} ** 256;
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
fn calculateEntropy(probabilities: [256]f128) f128 {
    var entropy: f128 = 0;
    for (probabilities) |prob| {
        if (prob > 0) {
            entropy += -prob * @log2(prob);
        }
    }
    return entropy;
}

/// Build Huffman Tree and generate codes
fn buildHuffmanTree() void {}
