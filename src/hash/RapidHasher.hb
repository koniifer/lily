/*
* This source file is an implementation of the RapidHash algorithm from https://github.com/Nicoshev/rapidhash,
* originally written by Nicolas De Carli under the MIT license.
*
* Changes to the original code were made to meet the simplicity requirements of this implementation.
* Behaviour aims to be equivalent but not identical to the original code.
*
* The following is the license under which this source file is distributed:
*
* Copyright 2025 Nicolas De Carli
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

lily.{mem, target, TypeInfo} := @use("../lib.hb")

$mum := fn(a: uint, b: uint): struct {
	.hi: uint;
	.lo: uint;
} {
	a_lo: uint = @as(u32, @int_cast(a))
	b_lo: uint = @as(u32, @int_cast(b))
	a_hi: uint = @as(u32, @int_cast(a >> 32))
	b_hi: uint = @as(u32, @int_cast(b >> 32))

	lo_lo := a_lo * b_lo
	lo_hi := a_lo * b_hi
	hi_lo := a_hi * b_lo
	hi_hi := a_hi * b_hi

	carry := (lo_hi & 0xFFFFFFFF) + (hi_lo & 0xFFFFFFFF) + (lo_lo >> 32)
	hi := hi_hi + (lo_hi >> 32) + (hi_lo >> 32) + (carry >> 32)
	lo := carry << 32 | (lo_lo & 0xFFFFFFFF)
	return .(hi, lo)
}

$mix := fn(a: uint, b: uint): uint {
	prod := mum(a, b)
	return prod.hi ^ prod.lo
};

.seed: uint;
.original_seed: uint;
.a: uint;
.b: uint;
.size: uint

RapidHasher := @CurrentScope()

$new := fn(seed: uint): RapidHasher {
	return .(seed, seed, 0, 0, 0)
}
$deinit := fn(self: ^RapidHasher): void {
	self.* = idk
}
$reset := fn(self: ^RapidHasher): void {
	self.seed = self.original_seed
	self.a = 0
	self.b = 0
	self.size = 0
}
$default := fn(): RapidHasher {
	a := 0
	target.rand_fill(@bit_cast(&a), @size_of(uint))
	return .new(a)
}
$write := fn(self: ^RapidHasher, _v: @Any()): void {
	$T := TypeInfo(@TypeOf(_v))
	$if T.internal_kind == .Struct & T.offset != 1 {
		@error("Does not support structs of align != 1 (or single field) yet.")
	}

	v: []u8 = idk

	$if T.internal_kind == .SliceOrArray {
		v = mem.as_bytes(_v[..])
	} else $if T.internal_kind == .Pointer {
		v = mem.as_bytes(_v)
	} else {
		v = mem.as_bytes(&_v)
	}

	self.size += v.len
	self.seed ^= mix(self.seed ^ 0x2d358dccaa6c78a5, 0x8bb84b93962eacc9 ^ self.size)

	len := v.len
	ptr := v.ptr

	if len <= 16 {
		if len >= 8 {
			self.a ^= @as(^uint, @bit_cast(ptr)).*
			self.b ^= @as(^uint, @bit_cast(ptr + len - 8)).*
		} else if len >= 4 {
			self.a ^= @as(^u32, @bit_cast(ptr)).*
			self.b ^= @as(^u32, @bit_cast(ptr + len - 4)).*
		} else {
			self.a ^= @as(uint, ptr.*) << 45 | (ptr + len - 1).* | (ptr + (len >> 1)).*
		}
	} else {
		see1 := self.seed
		see2 := self.seed
		loop if len < 96 break else {
			self.seed = mix(@as(^uint, @bit_cast(ptr)).* ^ 0x2d358dccaa6c78a5, @as(^uint, @bit_cast(ptr + 8)).* ^ self.seed)
			see1 = mix(@as(^uint, @bit_cast(ptr + 16)).* ^ 0x8bb84b93962eacc9, @as(^uint, @bit_cast(ptr + 24)).* ^ see1)
			see2 = mix(@as(^uint, @bit_cast(ptr + 32)).* ^ 0x4b33a62ed433d4a3, @as(^uint, @bit_cast(ptr + 40)).* ^ see2)
			self.seed = mix(@as(^uint, @bit_cast(ptr + 48)).* ^ 0x2d358dccaa6c78a5, @as(^uint, @bit_cast(ptr + 56)).* ^ self.seed)
			see1 = mix(@as(^uint, @bit_cast(ptr + 64)).* ^ 0x8bb84b93962eacc9, @as(^uint, @bit_cast(ptr + 72)).* ^ see1)
			see2 = mix(@as(^uint, @bit_cast(ptr + 80)).* ^ 0x4b33a62ed433d4a3, @as(^uint, @bit_cast(ptr + 88)).* ^ see2)
			ptr += 96
			len -= 96
		}
		if len >= 48 {
			self.seed = mix(@as(^uint, @bit_cast(ptr)).* ^ 0x2d358dccaa6c78a5, @as(^uint, @bit_cast(ptr + 8)).* ^ self.seed)
			see1 = mix(@as(^uint, @bit_cast(ptr + 16)).* ^ 0x8bb84b93962eacc9, @as(^uint, @bit_cast(ptr + 24)).* ^ see1)
			see2 = mix(@as(^uint, @bit_cast(ptr + 32)).* ^ 0x4b33a62ed433d4a3, @as(^uint, @bit_cast(ptr + 40)).* ^ see2)
			ptr += 48
			len -= 48
		}
		self.seed ^= see1 ^ see2

		if len > 16 {
			self.seed = mix(@as(^uint, @bit_cast(ptr)).* ^ 0x4b33a62ed433d4a3, @as(^uint, @bit_cast(ptr + 8)).* ^ self.seed ^ 0x8bb84b93962eacc9)
			if len > 32 {
				self.seed = mix(@as(^uint, @bit_cast(ptr + 16)).* ^ 0x4b33a62ed433d4a3, @as(^uint, @bit_cast(ptr + 24)).* ^ self.seed)
			}
		}
		self.a ^= @as(^uint, @bit_cast(ptr + len - 16)).*
		self.b ^= @as(^uint, @bit_cast(ptr + len - 8)).*
	}

	self.a ^= 0x8bb84b93962eacc9
	self.b ^= self.seed
	prod := mum(self.a, self.b)
	self.a = prod.lo
	self.b = prod.hi
}

$finish := fn(self: ^RapidHasher): uint {
	return mix(self.a ^ 0x2d358dccaa6c78a5 ^ self.size, self.b ^ 0x8bb84b93962eacc9)
}
