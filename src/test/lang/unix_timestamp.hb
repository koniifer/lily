/*
 * exit: 0
 */

$unix_timestamp := fn(year: uint, month: u8, day: u8, hour: u8, minute: u8, second: u8): uint {
	is_leap := year % 4 == 0 & (year % 100 != 0 | year % 400 == 0)
	days_since_epoch := (year - 1970) * 365 + (year - 1) / 4 - (year - 1) / 100 + (year - 1) / 400 - 477
	idx := month - 1
	sum_nonleap := (idx < 2) * idx * 31 + (idx >= 2) * (59 + (153 * (idx - 2) + 2) / 5)
	total_days := days_since_epoch + day + sum_nonleap + is_leap * (month > 2)
	return total_days * 86400 + hour * 3600 + minute * 60 + second
}

main := fn(): u8 {
	r0 := unix_timestamp(2025, 1, 31, 21, 53, 26) != 1738360406
	r1 := unix_timestamp(1970, 1, 1, 0, 0, 0) != 0
	r2 := unix_timestamp(2038, 1, 19, 3, 14, 8) != 1 << 31
	return r0 | r1 | r2
}