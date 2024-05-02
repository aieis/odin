package launcher

import "core:fmt"
import "core:os"

import SDL "vendor:sdl2"
import gl "vendor:OpenGL"

main :: proc() {
    progs, err := find_progs(Prog_Dir)

    if err != os.ERROR_NONE {
        fmt.eprintln("Failed to find programs.")
        return
    }

    defer prog_list_delete(progs)
         
    prog_list_print(progs)

    window := SDL.CreateWindow("Odin Launcher", SDL.WINDOWPOS_UNDEFINED, SDL.WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, {.OPENGL})
    if window == nil {
        fmt.eprintln("Failed to create window.")
        return;
    }

    defer SDL.DestroyWindow(window)

    gl_context := SDL.GL_CreateContext(window)
    SDL.GL_MakeCurrent(window, gl_context)
    gl.load_up_to(3, 3, SDL.gl_set_proc_address)

    loop : for {
        event : SDL.Event
        for SDL.PollEvent(&event) {
            #partial switch event.type {
                case .KEYDOWN:
                #partial switch event.key.keysym.sym {
                    case .ESCAPE: break loop
                }
                case .QUIT: break loop
            }
        }

        gl.ClearColor(0.6, 0.2, 0.4, 0.8)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        SDL.GL_SwapWindow(window)
    }
}
