.{Config, Target, fmt} := @use("lib.hb")

LogLevel := enum {
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}

log := fn(level: LogLevel, str: []u8): void {
	if level > Config.min_loglevel() return;
	match Target.current() {
		.LibC => match level {
			.Error => Target.printf_str("\{1b}[31mERROR\{1b}[0m: %.*s\n\0".ptr, str.len, str.ptr),
			.Warn => Target.printf_str("\{1b}[33mWARN\{1b}[0m: %.*s\n\0".ptr, str.len, str.ptr),
			.Info => Target.printf_str("\{1b}[32mINFO\{1b}[0m: %.*s\n\0".ptr, str.len, str.ptr),
			.Debug => Target.printf_str("\{1b}[34mDEBUG\{1b}[0m: %.*s\n\0".ptr, str.len, str.ptr),
			.Trace => Target.printf_str("\{1b}[35mTRACE\{1b}[0m: %.*s\n\0".ptr, str.len, str.ptr),
		},
		.AbleOS => return @eca(3, 1, Target.LogMsg.(level, str.ptr, str.len), @sizeof(Target.LogMsg)),
	}
}

// it's good enough i guess. dont write more than 4096 chars or you will explode.
print_buffer := @embed("assets/zeroed")

print := fn(any: @Any()): void {
	if @TypeOf(any) == []u8 {
		match Target.current() {
			.LibC => Target.printf_str("%.*s\n\0".ptr, any.len, any.ptr),
			.AbleOS => info(any),
		}
	} else {
		// limits len to size of buffer - 1
		len := fmt.format(print_buffer[0..@sizeof(@TypeOf(print_buffer)) - 1], any)
		print_buffer[len] = 0
		// ! (compiler) bug: not inlining here causes compiler panic
		@inline(print, print_buffer[0..len])
	}
}

printf := fn(str: []u8, any: @Any()): void {
	len := fmt.format_with_str(str, print_buffer[0..@sizeof(@TypeOf(print_buffer)) - 1], any)
	print_buffer[len] = 0
	@inline(print, print_buffer[0..len])
}

$error := fn(message: []u8): void return log(.Error, message)
$warn := fn(message: []u8): void return log(.Warn, message)
$info := fn(message: []u8): void return log(.Info, message)
$debug := fn(message: []u8): void return log(.Debug, message)
$trace := fn(message: []u8): void return log(.Trace, message)