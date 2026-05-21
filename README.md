# Conway's Game of Life in Mojo

A GPU-accelerated Conway's Game of Life implementation written in Mojo using pygame for rendering.
Based on the tutorial at https://mojolang.org/docs/manual/get-started/

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
