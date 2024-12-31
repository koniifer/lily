.{Vec, RawVec} := @use("vec.hb")

Error := enum {
	KeyNotFound,
	OutOfRange,
	Full,
}