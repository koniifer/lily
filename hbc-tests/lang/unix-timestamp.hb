expected := .{
	exit: 0,
}

sum_days := uint.[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]

unix_timestamp_secs_lookup_table := fn(year: uint, month: uint, day: uint, hour: uint, minute: uint, second: uint): uint {
	is_leap := year % 4 == 0 & (year % 100 != 0 | year % 400 == 0)
	days_since_epoch := year * 365 + (year - 1) / 4 - (year - 1) / 100 + (year - 1) / 400 - 719527
	total_days := days_since_epoch + day + sum_days[month - 1] + is_leap * (month > 2) - 1;
	return total_days * 86400 + hour * 3600 + minute * 60 + second
}

unix_timestamp_secs := fn(year: uint, month: uint, day: uint, hour: uint, minute: uint, second: uint): uint {
	is_leap := year % 4 == 0 & (year % 100 != 0 | year % 400 == 0)
	days_since_epoch := year * 365 + (year - 1) / 4 - (year - 1) / 100 + (year - 1) / 400 - 719527
	// relies on underflowing in (153 * month - 162) / 5 when month = 1
	sum_nonleap := (month < 3) * (month - 1) * 31 + (month >= 3) * (153 * month - 162) / 5
	total_days := days_since_epoch + day + sum_nonleap + is_leap * (month > 2) - 1
	return total_days * 86400 + hour * 3600 + minute * 60 + second
}

main := fn(): bool {
	// random date
	r := unix_timestamp_secs(2025, 1, 31, 21, 53, 26) != 1738360406
	// unix epoch
	r |= unix_timestamp_secs(1970, 1, 1, 0, 0, 0) != 0
	// y2k38
	r |= unix_timestamp_secs(2038, 1, 19, 3, 14, 8) != 1 << 31
	// end of year
	r |= unix_timestamp_secs(1970, 12, 31, 23, 59, 59) != 31535999
	// this doesnt pass: inlining here gives incorrect value.
	r |= @inline(unix_timestamp_secs, 2025, 1, 31, 21, 53, 26) != unix_timestamp_secs(2025, 1, 31, 21, 53, 26)
	r |= unix_timestamp_secs_lookup_table(2025, 1, 31, 21, 53, 26) != unix_timestamp_secs(2025, 1, 31, 21, 53, 26)
	r |= @inline(unix_timestamp_secs_lookup_table, 2025, 1, 31, 21, 53, 26) != unix_timestamp_secs(2025, 1, 31, 21, 53, 26)
	return r
}