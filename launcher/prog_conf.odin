package launcher

import "core:os"
import "core:fmt"
import "core:strings"

File_Copy :: struct {
    src: string,
    dst: string
}

Prog_Data :: struct {
    path: string,
    name: string,

    app_path: string,
    app_name: string
}

Prog_Conf :: struct {
    using prog : Prog_Data,
    conf_name: string,
    file_copy : [] File_Copy
}

dirlist_delete :: proc(file_infos : []os.File_Info) {
    for finfo in file_infos {
        os.file_info_delete(finfo)
    }
    delete(file_infos)
}

file_copy_delete :: proc(fc : File_Copy) {
    using fc
    delete(src)
    delete(dst)
}

prog_data_clone :: proc (pd : Prog_Data) -> Prog_Data {
    using pd
    npath := strings.clone(path)
    napp_path := strings.clone(app_path)

    return Prog_Data {
        path = npath,
        name = basename(npath),
        app_path = napp_path,
        app_name = basename(napp_path)
    }
}

prog_data_delete :: proc(pd : Prog_Data) {
    using pd
    delete(path)
    delete(app_path)
}

prog_conf_delete :: proc(pc : Prog_Conf) {
    using pc
    prog_data_delete(prog)
    delete(conf_name)
    for fc in file_copy {
        file_copy_delete(fc)
    }
    delete(file_copy)
}

prog_eligible :: proc(dirinfo: os.File_Info) -> (file: os.File_Info, succ: bool) {
    succ = false

    fd : os.Handle
    err : os.Errno
    fd, err = os.open(dirinfo.fullpath)
    if err != os.ERROR_NONE {
        return
    }

    defer os.close(fd)

    files : []os.File_Info
    files, err = os.read_dir(fd, 0)
    if err != os.ERROR_NONE {
        return
    }

    defer dirlist_delete(files)

    for file in files {
        size := len(file.name)

        if size < Target_Ext_Len {
            continue
        }

        if file.name[size - Target_Ext_Len:size] == Target_Ext {
            using file
            nfullpath := strings.clone(fullpath)
            nname := basename(fullpath)
            fc := os.File_Info {
                nfullpath,
                nname,
                size,
                mode,
                is_dir,
                creation_time,
                modification_time,
                access_time
            }

            return fc, true
        }
    }

    return
}

prog_conf_collect :: proc(prog : Prog_Data) -> []Prog_Conf {

    progs := make([dynamic] Prog_Conf, 0, 1)
    defprog := Prog_Conf {
        prog = prog_data_clone(prog),
        conf_name = strings.clone(prog.name),
    }

    sarr := [?]string {prog.path, Prog_Var_Src}
    vardir := strings.concatenate(sarr[:])
    defer delete(vardir)

    if !os.is_dir(vardir) {
        append(&progs, defprog)
        return progs[:]
    }

    fd, err := os.open(vardir)
    if err != os.ERROR_NONE {
        append(&progs, defprog)
        return progs[:]
    }

    defer os.close(fd)

    dirs : []os.File_Info
    dirs, err = os.read_dir(fd, 0)
    if err != os.ERROR_NONE {
        append(&progs, defprog)
        return progs[:]
    }

    defer dirlist_delete(dirs)

    defer prog_conf_delete(defprog)

    sarr2 := [?]string {prog.path, Prog_Var_Dst}
    dstroot := strings.concatenate(sarr2[:])
    defer delete(dstroot)

    for dir in dirs {
        if !dir.is_dir {
            continue
        }
        nfd : os.Handle
        nfd, err = os.open(dir.fullpath)
        if err != os.ERROR_NONE {
            continue
        }
        defer os.close(nfd)

        files : []os.File_Info
        files, err = os.read_dir(nfd, 0)
        defer dirlist_delete(files)

        file_copy := make([dynamic] File_Copy, 0, 1)
        for file in files {
            sarr3 := [?]string {dstroot, file.name}
            fc_ := File_Copy {
                src = strings.clone(file.fullpath),
                dst = strings.concatenate(sarr3[:])
            }

            append(&file_copy, fc_)
        }

        sarr4 := [?]string {prog.name, "/", dir.name}
        conf_ := Prog_Conf {
            prog = prog_data_clone(prog),
            conf_name = strings.concatenate(sarr4[:]),
            file_copy = file_copy[:]
        }

        append(&progs, conf_)
    }

    if len(progs) == 0 {
        append(&progs, defprog)
    }

    return progs[:]
}

find_progs :: proc(dirpath : string) -> (pd: []Prog_Conf, err: os.Errno){
    fd : os.Handle

    fd, err = os.open(dirpath)
    if err != os.ERROR_NONE {
        return
    }

    defer os.close(fd)

    dirs : []os.File_Info
    dirs, err = os.read_dir(fd, 0)
    if err != os.ERROR_NONE {
        return
    }

    defer dirlist_delete(dirs)

    valid_progs := make([dynamic]Prog_Conf, 0, 1)
    for prog in dirs {
        file, elig := prog_eligible(prog)
        if !elig {
            continue
        }
        defer os.file_info_delete(file)

        npath := strings.clone(prog.fullpath)
        napp_path := strings.clone(file.fullpath)
        pd_ := Prog_Data {
            path = npath,
            name = basename(npath),
            app_path = napp_path,
            app_name = basename(napp_path)
        }

        defer prog_data_delete(pd_)

        confs := prog_conf_collect(pd_)
        defer delete(confs)

        for conf in confs { append(&valid_progs, conf) }
    }

    return valid_progs[:], os.ERROR_NONE
}

prog_list_delete :: proc(progs : []Prog_Conf) {
    for prog in progs {
        prog_conf_delete(prog)
    }
    delete(progs)
}

prog_conf_print :: proc(prog : Prog_Conf) {
    fmt.printf("Application \"%v\":\n", prog.conf_name)
    fmt.printf("Root Name: %v\n", prog.name)
    fmt.printf("Root Path: %v\n", prog.path)
    fmt.printf("Application name: %v\n", prog.app_name)
    fmt.printf("Application Path: %v\n", prog.app_path)

    if len(prog.file_copy) > 0 {
        fmt.printf("Var files:\n")
        for fc in prog.file_copy {
            fmt.printf("\t\"%v\" => \"%v\"\n", fc.src, fc.dst)
        }
        fmt.println("EOL")
    }

}

prog_list_print :: proc(progs : []Prog_Conf) {
    for prog in progs {
        prog_conf_print(prog)
        fmt.println()
    }
}
