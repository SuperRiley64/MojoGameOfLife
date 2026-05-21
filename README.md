# Conway's Game of Life in Mojo

A GPU-accelerated Conway's Game of Life implementation written in Mojo using pygame for rendering.
Based on the tutorial at https://mojolang.org/docs/manual/get-started/

## My benchmark results
1000x1000 grid, 10,000 iterations:
```
===== CPU Benchmark =====
CPU Time: 25.611646958001074
CPU GPS: 390.44736234254555

===== GPU Benchmark =====
Using GPU: Apple M4
GPU Time: 10.806141957989894
GPU GPS: 925.3996513164585

===== Speedup =====
GPU speedup: 2.370100916457443 x
```

## Requirements

- Linux, MacOS, or WSL
- Python 3.12
- Git
- uv

## Run it for yourself

Clone the repository:

```bash
git clone https://github.com/SuperRiley64/MojoGameOfLife
cd MojoGameOfLife
```

Install Python 3.12 with uv:

```bash
uv python install 3.12
uv python pin 3.12
```

Create and activate a virtual environment:

```bash
uv venv
source .venv/bin/activate
```

Install dependencies:

```bash
uv pip install mojo pygame
```

## Running

Run the application:

```bash
mojo life.mojo
```

Run the benchmark (no pygame bottleneck):

```bash
mojo life_bench.mojo
```
