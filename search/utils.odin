package search

basename :: proc(name: string) -> (base: string) {
	name := name
	if len(name) > 3 && name[:3] == `\\?` {
		name = name[3:]
	}

	if len(name) == 2 && name[1] == ':' {
		return "."
	} else if len(name) > 2 && name[1] == ':' {
		name = name[2:]
	}
	i := len(name)-1

	for ; i > 0 && (name[i] == '/' || name[i] == '\\'); i -= 1 {
		name = name[:i]
	}
	for i -= 1; i >= 0; i -= 1 {
		if name[i] == '/' || name[i] == '\\' {
			name = name[i+1:]
			break
		}
	}
	return name
}
