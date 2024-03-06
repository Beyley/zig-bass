const std = @import("std");

pub fn linkBass(module: *std.Build.Module) void {
    const target = module.resolved_target.?.result;

    const bass_lib_path = blk: {
        switch (target.cpu.arch) {
            .x86_64 => {
                switch (target.os.tag) {
                    .windows => break :blk root_path ++ "libs/x86_64-windows-gnu",
                    .linux => break :blk root_path ++ "libs/x86_64-linux-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for x86_64"),
                }
            },
            .aarch64 => {
                switch (target.os.tag) {
                    .windows => break :blk root_path ++ "libs/aarch64-windows-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for aarch64"),
                }
            },
            else => @panic("Unknown CPU arch for Bass"),
        }
    };
    module.addLibraryPath(.{ .path = bass_lib_path });
    module.linkSystemLibrary("bass", .{});
    //On MacOS, for the libbass.dylib to resolve, we need to add this as an rpath
    if (target.os.tag.isDarwin()) {
        module.addRPath(.{ .path = "@executable_path" });
    }
}

pub fn installBass(b: *std.Build, target: std.Target) void {
    const bass_lib_path = blk: {
        switch (target.cpu.arch) {
            .x86_64 => {
                switch (target.os.tag) {
                    .windows => break :blk root_path ++ "libs/x86_64-windows-gnu",
                    .linux => break :blk root_path ++ "libs/x86_64-linux-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for x86_64"),
                }
            },
            .aarch64 => {
                switch (target.os.tag) {
                    .windows => break :blk root_path ++ "libs/aarch64-windows-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for aarch64"),
                }
            },
            else => @panic("Unknown CPU arch for Bass"),
        }
    };

    const bass_lib_file = blk: {
        switch (target.os.tag) {
            .windows => break :blk "bass.dll",
            .linux => break :blk "libbass.so",
            .macos => break :blk "libbass.dylib",
            else => @panic("Unknown OS for bass"),
        }
    };

    b.installBinFile(b.fmt("{s}/{s}", .{ bass_lib_path, bass_lib_file }), bass_lib_file);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig_bass_test",
        .root_source_file = .{ .path = root_path ++ "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.addIncludePath(.{ .path = "src/" });
    b.installArtifact(exe);

    linkBass(exe);
    installBass(b, target);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib = b.addStaticLibrary(.{
        .name = "zig-bass",
        .root_source_file = .{ .path = root_path ++ "src/bass.zig" },
        .target = target,
        .optimize = optimize,
    });
    linkBass(lib);
    b.installArtifact(lib);
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";
