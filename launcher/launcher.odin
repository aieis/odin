package launcher

import "core:fmt"
import "core:os"

import raylib "vendor:raylib"

WINDOW_WIDTH :: 900
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Odin Launcher"
WINDOW_MARGINS :: 50
WINDOW_INNER_WIDTH :: WINDOW_WIDTH - WINDOW_MARGINS * 2
WINDOW_INNER_HEIGHT :: WINDOW_HEIGHT - WINDOW_MARGINS * 2

PROG_WIDTH :: 100
PROG_HEIGHT :: 100
PROG_MARGIN :: 5
PROG_INNER_WIDTH :: PROG_WIDTH - PROG_MARGIN * 2
PROG_INNER_HEIGHT :: PROG_HEIGHT - PROG_MARGIN * 2

main :: proc() {
    progs, err := find_progs(Prog_Dir)

    if err != os.ERROR_NONE {
        fmt.eprintln("Failed to find programs.")
        return
    }

    defer prog_list_delete(progs)

    raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
    defer raylib.CloseWindow()

    cols :: WINDOW_INNER_WIDTH / PROG_WIDTH

    cols_rem := len(progs) % cols
    rows := len(progs) / cols + (1 if cols_rem > 0 else 0)
    
    x_offset :: (WINDOW_INNER_WIDTH - cols * PROG_WIDTH) / 2 + WINDOW_MARGINS
    y_offset := (WINDOW_INNER_HEIGHT - rows * PROG_HEIGHT) / 2 + WINDOW_MARGINS

    x_final_offset := (WINDOW_INNER_WIDTH -  cols_rem * PROG_WIDTH) / 2 + WINDOW_MARGINS
    
    
    loop : for {
        if raylib.WindowShouldClose() {
            break loop
        }

        raylib.BeginDrawing()
        {
            raylib.ClearBackground(raylib.GRAY)
            for prog, i in progs {
                row := i % cols
                x : f32 = cast(f32) row * PROG_WIDTH + cast(f32) (x_offset if row != cols_rem else x_final_offset)
                y : f32 = cast(f32) (i / cols) * PROG_HEIGHT + cast(f32) y_offset
                
                rec := raylib.Rectangle {
                    x + PROG_MARGIN,
                    y + PROG_MARGIN,
                    PROG_INNER_WIDTH,
                    PROG_INNER_HEIGHT
                }

                raylib.DrawRectangleRoundedLines(rec, 0.01, 1, -1, raylib.LIGHTGRAY)
            }
        }
        raylib.EndDrawing()
    }
}
