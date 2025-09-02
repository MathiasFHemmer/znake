const std = @import("std");

fn addFiles(b: *std.Build, exe: *std.Build.Step.Compile, folder: []const u8) !void {
    var dir = try std.fs.cwd().openDir(folder, .{ .iterate = true });
    var it = dir.iterate();

    while (try it.next()) |file| {
        const name = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ folder, file.name });
        std.debug.print("adding for embeding {s}\n", .{name});
        switch (file.kind) {
            .file => {
                exe.root_module.addAnonymousImport(name, .{ .root_source_file = b.path(name) });
            },
            .directory => {
                try addFiles(b, exe, name);
            },
            else => {},
        }
    }
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.linkLibrary(raylib_artifact);
    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("raygui", raygui);
    exe_mod.addImport("snake_zig_lib", lib_mod);

    const exe = b.addExecutable(.{
        .name = "snake_zig",
        .root_module = exe_mod,
    });

    addFiles(b, exe, "shaders") catch |err| {
        std.debug.panic("{any}", .{err});
    };

    b.installArtifact(exe);

    // Run Steps
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Unit tests - Not to worry right now
    // const lib_unit_tests = b.addTest(.{
    //     .root_module = lib_mod,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_module = exe_mod,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
