.{target, target_c_native, target_hbvm_ableos} := @use("lib.hb")

LogLevel := enum {
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}

log := fn(level: LogLevel, str: []u8): void {
	if target == target_hbvm_ableos {
		return @eca(3, 1, target.LogMsg.(level, str.ptr, str.len), @sizeof(target.LogMsg))
	} else if target == target_c_native {
		match level {
			.Error => target.printf_str("\{1b}[31mERROR\{1b}[0m: %s\n\0".ptr, str.ptr),
			.Warn => target.printf_str("\{1b}[33mWARN\{1b}[0m: %s\n\0".ptr, str.ptr),
			.Info => target.printf_str("\{1b}[32mINFO\{1b}[0m: %s\n\0".ptr, str.ptr),
			.Debug => target.printf_str("\{1b}[34mDEBUG\{1b}[0m: %s\n\0".ptr, str.ptr),
			.Trace => target.printf_str("\{1b}[35mTRACE\{1b}[0m: %s\n\0".ptr, str.ptr),
		}
	}
}

$print := fn(str: []u8): void {
	if target == target_c_native {
		target.puts(str.ptr)
	} else if target == target_hbvm_ableos {
		info(str)
	}
}

$error := fn(message: []u8): void return log(LogLevel.Error, message)
$warn := fn(message: []u8): void return log(LogLevel.Warn, message)
$info := fn(message: []u8): void return log(LogLevel.Info, message)
$debug := fn(message: []u8): void return log(LogLevel.Debug, message)
$trace := fn(message: []u8): void return log(LogLevel.Trace, message)