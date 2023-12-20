# Memsimd
This Zig library offers a set of memory utilities optimized with SIMD (Single Instruction, Multiple Data) features, specifically leveraging SSE2, SSE4.2, and AVX instructions. These utilities aim to accelerate common memory operations for improved performance on compatible CPUs.

### Benchmarks
One of the main goals of this library is provide a fast way to compare two slices. Here's a benchmark conducted by comparing a million strings with random lengths. As you can see the AVX version is roughly 3.5x, SSE2 and SSE4.2 versions are roughly 3x faster than normal string comparison.
```
No SIMD strcmp took: 191ms
SSE2 strcmp took: 73ms
SS4.2 strcmp took: 60ms
AVX strcmp took: 54ms
```
You can run the benchmarks by yourself with:
```bash
zig build bench -Doptimize=ReleaseFast
```

### License
This library is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.