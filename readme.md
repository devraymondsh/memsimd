# Memsimd
This Zig library offers a set of memory utilities optimized with SIMD (Single Instruction, Multiple Data) features, specifically leveraging SSE2, SSE4.2, and AVX instructions. These utilities aim to accelerate common memory operations for improved performance on compatible CPUs.

### Benchmarks
One of the main goals of this library is to provide a fast way to compare two slices. Here's a benchmark conducted by comparing a million strings with random lengths. According to the benchmark the AVX version is roughly 3.5x, SSE2 and SSE4.2 versions are roughly 3x faster than normal string comparison.

Here are the benchmark's results on the Intel core i5 12400. As you can see some CPUs like this may use AVX's performance capabilities for SSE2 instructions. So don't always expect the SSE4.2 to be faster than the SSE2 version.
```
No SIMD strcmp took: 190ms
SSE2 strcmp took: 56ms
SS4.2 strcmp took: 73ms
AVX strcmp took: 54ms
```

Here are the benchmark results on AMD R9 5900HS. You can see here that the SSE4.2 version is a little faster than the SSE2 version as some may expect:
```
No SIMD strcmp took: 292ms
SSE2 strcmp took: 100ms
SS4.2 strcmp took: 92ms
AVX strcmp took: 78ms
```

You can run the benchmarks by yourself with:
```bash
zig build bench -Doptimize=ReleaseFast
```

### License
This library is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.