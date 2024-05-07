package launcher

import "core:fmt"
import "core:os"
import "core:strings"

import raylib "vendor:raylib"

WINDOW_WIDTH :: 900
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Odin Launcher"
WINDOW_MARGINS :: 50
WINDOW_INNER_WIDTH :: WINDOW_WIDTH - WINDOW_MARGINS * 2
WINDOW_INNER_HEIGHT :: WINDOW_HEIGHT - WINDOW_MARGINS * 2

PROG_WIDTH :: 100
PROG_HEIGHT :: 100
PROG_MARGIN :: 10
PROG_INNER_WIDTH :: PROG_WIDTH - PROG_MARGIN * 2
PROG_INNER_HEIGHT :: PROG_HEIGHT - PROG_MARGIN * 2

COLOR_BG :: raylib.Color {51, 51, 51, 255}
COLOR_FG :: raylib.Color {100, 100, 100, 255}
COLOR_SEL :: raylib.Color {170, 170, 170, 255}

FONT := raylib.GetFontDefault()
FONT_SIZE :: 1.0
FONT_SPACING :: 1.0

Prog_UI :: struct {
    name : cstring,
    text_dim : raylib.Vector2
}

prog_ui_list_from_confs :: proc (progs : [] Prog_Conf) -> []Prog_UI {
    uis := make([dynamic]Prog_UI, 0, len(progs))

    for prog in progs {
        name := strings.clone_to_cstring(prog.app_name)
        dim := 99999
        start := 0
        text_dims : raylib.Vector2
        for {
            text_dims = raylib.MeasureTextEx(FONT, name, FONT_SIZE, FONT_SPACING)
            if text_dims[0] < PROG_INNER_WIDTH || len(name) == 0 {
                break
            }
        }
        append(&uis, Prog_UI {name, text_dims})
    }

    return uis[:]
}

prog_ui_list_delete :: proc(uis : [] Prog_UI) {
    for ui in uis {
        delete_cstring(ui.name)
    }
    delete(uis)
}

in_region :: proc(pos : raylib.Vector2, rec : raylib.Rectangle) -> bool {
    return pos[0] >= rec.x && pos[0] <= rec.x + rec.width && pos[1] >= rec.y && pos[1] <= rec.y + rec.height;
}


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


    prog_uis := prog_ui_list_from_confs(progs)
    defer prog_ui_list_delete(prog_uis)
    
    idx_clicked := -1
    mouse_click := false
    
    main_loop : for {
        idx_clicked = -1

        mouse := raylib.GetMousePosition()
        mouse_click := raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT)

        if raylib.WindowShouldClose() {
            break main_loop
        }


        raylib.BeginDrawing()
        {
            raylib.ClearBackground(COLOR_BG)
            for prog_ui, i in prog_uis {
                col := i % cols
                row := i / cols
                x : f32 = cast(f32) col * PROG_WIDTH + cast(f32) (x_offset if row < rows-1 else x_final_offset)
                y : f32 = cast(f32) row * PROG_HEIGHT + cast(f32) y_offset

                rec := raylib.Rectangle {
                    x + PROG_MARGIN,
                    y + PROG_MARGIN,
                    PROG_INNER_WIDTH,
                    PROG_INNER_HEIGHT
                }

                color := COLOR_FG
                if in_region(mouse, rec) {
                    color = COLOR_SEL
                    idx_clicked = i
                }
            }
        }
        raylib.EndDrawing()

        if mouse_click && idx_clicked != -1 {
            break main_loop
        }
    }

    if mouse_click && idx_clicked != -1 {
        fmt.println("Launching program")
        fmt.println("=================")
        prog_conf_print(progs[idx_clicked])
    }

}
