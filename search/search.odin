package search

import "core:os"
import "core:fmt"

mod_main :: proc() {

  if len(os.args) == 1 {
    fmt.printf("USAGE: %v FILE\n", os.args[0])
    fmt.printf("ERR: Missing FILE argument.\n")
    return
  }

  file_name := os.args[1]

  file_bytes, succ := os.read_entire_file_from_filename(file_name)

  if !succ {
    fmt.printf("ERR: Could not read file %v. Ensure that the file exists.\n", file_name)
    return
  }

  file_str := cast(string) file_bytes

  fmt.printf("Contents of file %v:\n", file_name)

  fmt.printf("%v", file_str)
  fmt.println()
}
