from std import time
from std.gpu.host import DeviceContext

from gridv1 import Grid, GpuGrid
from std.python import Python


def run_display(
    var grid: Grid,
    background_color: String = "black",
    cell_color: String = "green",
    pause: Float64 = 0.1,
) raises -> None:
    window_height: Int = grid.rows
    window_width: Int = grid.cols

    # Import the pygame Python package
    pygame = Python.import_module("pygame")

    # Initialize pygame modules
    pygame.init()

    # Initialize FPS counter
    clock = pygame.time.Clock()
    font = pygame.font.SysFont("Consolas", 16)

    # Create a window and set its title
    window = pygame.display.set_mode(Python.tuple(window_width, window_height))
    pygame.display.set_caption("Conway's Game of Life")

    cell_fill_color = pygame.Color(cell_color)
    background_fill_color = pygame.Color(background_color)

    ctx = DeviceContext()
    gpu_grid = GpuGrid.from_grid(ctx, grid^)
    print("Using GPU:", ctx.name())

    running = True
    while running:
        # Poll for events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                # Quit if the window is closed
                running = False
            elif event.type == pygame.KEYDOWN:
                # Also quit if the user presses <Escape> or 'q'
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                    running = False

        # Clear the window
        window.fill(background_fill_color)

        pixels = pygame.PixelArray(window)

        for row in range(grid.rows):
            for col in range(grid.cols):
                if grid[row, col]:
                    pixels[col, row] = cell_fill_color

        pixels.close()

        # Update the FPS counter
        # Measure FPS
        fps = clock.get_fps()

        # Render FPS text
        fps_surface = font.render(
        "FPS: " + String(fps),
        True,
        pygame.Color("white"),
        )

        # Draw FPS text in top-left
        window.blit(fps_surface, Python.tuple(10, 10))

        # Update the display
        pygame.display.update()
        clock.tick()

        # Pause to let the user appreciate the scene
        #time.sleep(pause)

        # Next generation
        gpu_grid.evolve()
        grid = gpu_grid.to_grid()

    # Shut down pygame cleanly
    pygame.quit()


def main() raises:
    start = Grid.random(1000, 1000)
    run_display(start^)