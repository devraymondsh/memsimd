# Memsimd
This Zig library offers a set of memory utilities optimized with SIMD (Single Instruction, Multiple Data) features, specifically leveraging SSE2, SSE4.2, and AVX instructions. These utilities aim to accelerate common memory operations for improved performance on compatible CPUs.

### Benchmarks
One of the main goals of this library is to provide a fast way to compare two slices. Here's a benchmark conducted by comparing a million strings with random lengths. According to the benchmark the AVX version is roughly 3.5x, SSE2 and SSE4.2 versions are roughly 3x faster than normal string comparison.

Here are the benchmark's results on the Intel core i5 12400. As you can see some CPUs like this may use AVX's performance capabilities for SSE2 instructions. So don't always expect the SSE4.2 to be faster than the SSE2 version.
```
C's builtin strcmp took: 148ms
Zig's std SIMD strcmp took: 143ms
No SIMD strcmp took: 199ms
SSE2 strcmp took: 54ms
SS4.2 strcmp took: 75ms
AVX strcmp took: 46ms
```

Here are the benchmark's results on Mac M1 (Aarch64):
```
C's builtin strcmp took: 528ms
Zig's std SIMD strcmp took: 301ms
No SIMD strcmp took: 287ms
SVE strcmp took: 55ms
```

You can run the benchmarks by yourself with:
```bash
zig build bench -Doptimize=ReleaseFast
```

### Usage
#### 1. Add memsimd to your `build.zig.zon`
```zig
.{
    .name = "<your_apps_name>",
    .version = "<your_apps_vesion>",
    .dependencies = .{
        // memsimd v0.1.0
        .memsimd = .{
            .url = "https://github.com/devraymondsh/memsimd/archive/refs/tags/v0.1.0.tar.gz",
            .hash = "12208ce7ad284db242c305056b813b01213b74527310cc4c55523e09ff8db4ba5f9d",
        },
    },
}
```
#### 2. Add memsimd to your `build.zig`
```zig
const memsimd = b.dependency("memsimd", .{
    .target = target,
    .optimize = optimize,
});
exe.addModule("memsimd", memsimd.module("memsimd"));
```

### License
This library is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
