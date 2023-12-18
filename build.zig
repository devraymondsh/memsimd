const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const memsimd_module = b.createModule(.{
        .source_file = .{ .path = "src/root.zig" },
    });

    const lib = b.addStaticLibrary(.{
        .name = "memsimd",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const tests = b.step("test", "Run the tests");
    const eql_tests = b.addTest(.{
        .name = "eql_tests",
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/tests/eql.zig" },
    });
    const eql_tests_run = b.addRunArtifact(eql_tests);
    eql_tests.addModule("memsimd", memsimd_module);
    tests.dependOn(&eql_tests_run.step);

    const bench_step = b.step("bench", "Run the string benchmark");
    const benchmarks_exe = b.addExecutable(.{
        .name = "memsimd-streql-benchmark",
        .root_source_file = .{ .path = "src/bench/streql.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_benchmarks = b.addRunArtifact(benchmarks_exe);
    benchmarks_exe.addModule("memsimd", memsimd_module);
    bench_step.dependOn(&run_benchmarks.step);
}
