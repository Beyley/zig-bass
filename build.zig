const std = @import("std");

pub fn linkBass(exe: *std.Build.Step.Compile) void {
    const bass_lib_path = blk: {
        switch (exe.target.getCpuArch()) {
            .x86_64 => {
                switch (exe.target.getOsTag()) {
                    .windows => break :blk root_path ++ "libs/x86_64-windows-gnu",
                    .linux => break :blk root_path ++ "libs/x86_64-linux-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for x86_64"),
                }
            },
            .aarch64 => {
                switch (exe.target.getOsTag()) {
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for aarch64"),
                }
            },
            else => @panic("Unknown CPU arch for Bass"),
        }
    };
    exe.addLibraryPath(bass_lib_path);
    exe.linkSystemLibrary("bass");
}

pub fn installBass(b: *std.Build, target: std.zig.CrossTarget) void {
    const bass_lib_path = blk: {
        switch (target.getCpuArch()) {
            .x86_64 => {
                // std.debug.print("{any}\n", .{target.getOsTag()});
                switch (target.getOsTag()) {
                    .windows => break :blk root_path ++ "libs/x86_64-windows-gnu",
                    .linux => break :blk root_path ++ "libs/x86_64-linux-gnu",
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for x86_64"),
                }
            },
            .aarch64 => {
                switch (target.getOsTag()) {
                    .macos => break :blk root_path ++ "libs/universal-macos",
                    else => @panic("Unknown OS for aarch64"),
                }
            },
            else => @panic("Unknown CPU arch for Bass"),
        }
    };

    const bass_lib_file = blk: {
        switch (target.getOsTag()) {
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
}

fn root() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const root_path = root() ++ "/";
