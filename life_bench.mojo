from std import time
from std.gpu.host import DeviceContext

from gridv1 import Grid, GpuGrid
from std.python import Python


def main() raises:
    var rows = 1000
    var cols = 1000
    var generations = 10000

    pytime = Python.import_module("time")

    print("Generating random grid...")
    var start = Grid.random(rows, cols)

    print("")
    print("===== CPU Benchmark =====")

    var cpu_grid = start.copy()

    # Start timer
    var cpu_start = pytime.perf_counter()

    for _ in range(generations):
        cpu_grid = cpu_grid.evolve()

    # End timer
    var cpu_end = pytime.perf_counter()

    var cpu_elapsed = cpu_end - cpu_start
    var cpu_gps = Float64(generations) / cpu_elapsed

    print("CPU Time:", cpu_elapsed)
    print("CPU GPS:", cpu_gps)

    print("")
    print("===== GPU Benchmark =====")

    var ctx = DeviceContext()

    print("Using GPU:", ctx.name())

    var gpu_grid = GpuGrid.from_grid(ctx, start^)

    # Start timer
    var gpu_start = pytime.perf_counter()

    for _ in range(generations):
        gpu_grid.evolve()

    # Make sure GPU work is fully complete
    ctx.synchronize()

    # End timer
    var gpu_end = pytime.perf_counter()

    var gpu_elapsed = gpu_end - gpu_start
    var gpu_gps = Float64(generations) / gpu_elapsed

    print("GPU Time:", gpu_elapsed)
    print("GPU GPS:", gpu_gps)

    print("")
    print("===== Speedup =====")

    print("GPU speedup:", gpu_gps / cpu_gps, "x")