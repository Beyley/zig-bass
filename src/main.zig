const std = @import("std");

const bass = @import("bass.zig");

pub fn main() !void {
    std.debug.print("Initializing Bass.\n", .{});

    try bass.init(.default, null, .{}, 0);
    defer bass.deinit();

    const version = bass.getVersion();

    std.debug.print("Bass version: {d}.{d}.{d}.{d}\n", .{ version.major, version.minor, version.revision, version.patch });

    const stream = try bass.createFileStream(.{ .file = .{ .path = "/home/beyley/badapple.mp3" } }, 0, .{});
    defer stream.deinit();

    try stream.play(true);
    try stream.setAttribute(.volume, 0.025);

    var buf: [1]u8 = [1]u8{0};
    std.debug.print("Press enter to pause...\n", .{});
    _ = try std.io.getStdIn().read(&buf);

    try stream.pause();

    std.debug.print("Press enter to unpause...\n", .{});
    _ = try std.io.getStdIn().read(&buf);

    try stream.play(false);

    std.debug.print("Press enter to exit...\n", .{});
    _ = try std.io.getStdIn().read(&buf);

    // while (true) {
    //     var position = try stream.getSecondPosition();

    //     std.debug.print("pos: {d}\n", .{position});
    // }
}
