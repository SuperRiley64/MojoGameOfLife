from std import random
from std.gpu import block_dim, block_idx, thread_idx
from std.gpu.host import DeviceContext
from std.memory import UnsafePointer
from std.gpu.host import DeviceContext, DeviceBuffer


comptime life_dtype = DType.int64
comptime block_size = 256


fn evolve_kernel(
    current: UnsafePointer[Scalar[life_dtype], MutAnyOrigin],
    next: UnsafePointer[Scalar[life_dtype], MutAnyOrigin],
    rows: UInt,
    cols: UInt,
    total: UInt,
):
    var tid = block_idx.x * block_dim.x + thread_idx.x

    if tid >= total:
        return

    var row = tid // cols
    var col = tid % cols

    var row_above = (row + rows - 1) % rows
    var row_below = (row + 1) % rows
    var col_left = (col + cols - 1) % cols
    var col_right = (col + 1) % cols

    var neighbors = (
        current[row_above * cols + col_left]
        + current[row_above * cols + col]
        + current[row_above * cols + col_right]
        + current[row * cols + col_left]
        + current[row * cols + col_right]
        + current[row_below * cols + col_left]
        + current[row_below * cols + col]
        + current[row_below * cols + col_right]
    )

    var alive = current[tid]
    var new_state = Scalar[life_dtype](0)

    if alive == 1 and (neighbors == 2 or neighbors == 3):
        new_state = Scalar[life_dtype](1)
    elif alive == 0 and neighbors == 3:
        new_state = Scalar[life_dtype](1)

    next[tid] = new_state


@fieldwise_init
struct Grid(Copyable, Writable):
    var rows: Int
    var cols: Int
    var data: List[Int]

    def write_to(self, mut writer: Some[Writer]):
        for row in range(self.rows):
            for col in range(self.cols):
                if self[row, col] == 1:
                    writer.write_string("*")
                else:
                    writer.write_string(" ")

            if row != self.rows - 1:
                writer.write_string("\n")

    @staticmethod
    def random(rows: Int, cols: Int) -> Self:
        random.seed()

        var data: List[Int] = []

        for _ in range(rows * cols):
            data.append(Int(random.random_si64(0, 1)))

        return Self(rows, cols, data^)

    def evolve(self) -> Self:
        var next_generation = List[Int]()

        for row in range(self.rows):
            var row_above = (row - 1) % self.rows
            var row_below = (row + 1) % self.rows

            for col in range(self.cols):
                var col_left = (col - 1) % self.cols
                var col_right = (col + 1) % self.cols

                var num_neighbors = (
                    self[row_above, col_left]
                    + self[row_above, col]
                    + self[row_above, col_right]
                    + self[row, col_left]
                    + self[row, col_right]
                    + self[row_below, col_left]
                    + self[row_below, col]
                    + self[row_below, col_right]
                )

                var new_state = 0

                if self[row, col] == 1 and (
                    num_neighbors == 2 or num_neighbors == 3
                ):
                    new_state = 1
                elif self[row, col] == 0 and num_neighbors == 3:
                    new_state = 1

                next_generation.append(new_state)
        return Self(self.rows, self.cols, next_generation^)

    def __getitem__(self, row: Int, col: Int) -> Int:
        return self.data[row * self.cols + col]

    def __setitem__(mut self, row: Int, col: Int, value: Int) -> None:
        self.data[row * self.cols + col] = value

@fieldwise_init
struct GpuGrid:
    var rows: Int
    var cols: Int
    var total: Int
    var grid_size: Int
    var ctx: DeviceContext
    var current_buffer: DeviceBuffer[life_dtype]
    var next_buffer: DeviceBuffer[life_dtype]

    @staticmethod
    def from_grid(ctx: DeviceContext, grid: Grid) raises -> Self:
        var total = grid.rows * grid.cols
        var grid_size = (total + block_size - 1) // block_size

        var current_buffer = ctx.enqueue_create_buffer[life_dtype](total)
        var next_buffer = ctx.enqueue_create_buffer[life_dtype](total)

        # Upload CPU grid data once.
        with current_buffer.map_to_host() as current_host:
            for i in range(total):
                current_host[i] = Scalar[life_dtype](grid.data[i])

        ctx.synchronize()

        return Self(
            grid.rows,
            grid.cols,
            total,
            grid_size,
            ctx,
            current_buffer^,
            next_buffer^,
        )

    def evolve(mut self) raises -> None:
        self.ctx.enqueue_function[evolve_kernel, evolve_kernel](
            self.current_buffer,
            self.next_buffer,
            UInt(self.rows),
            UInt(self.cols),
            UInt(self.total),
            grid_dim=self.grid_size,
            block_dim=block_size,
        )

        self.ctx.synchronize()

        # Swap buffers.
        var temp = self.current_buffer^
        self.current_buffer = self.next_buffer^
        self.next_buffer = temp^

    def to_grid(self) raises -> Grid:
        self.ctx.synchronize()

        var data = List[Int]()

        with self.current_buffer.map_to_host() as current_host:
            for i in range(self.total):
                data.append(Int(current_host[i]))

        return Grid(self.rows, self.cols, data^)

    def __getitem__(self, row: Int, col: Int) raises -> Int:
        ctx.synchronize()

        with self.current_buffer.map_to_host() as current_host:
            return Int(current_host[row * self.cols + col])