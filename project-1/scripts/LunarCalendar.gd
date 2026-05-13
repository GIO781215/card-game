extends Node

# Lunar calendar data for years 1900-2100 (from jjonline/calendar.js, MIT License)
# Encoding per entry:
#   bit 16 (0x10000): leap month has 30 days (0 = 29 days)
#   bits 15-4: regular months 1-12 size (1 = 30 days, 0 = 29 days)
#   bits 3-0: leap month number (0 = no leap month)
const _LUNAR_INFO: Array = [
	0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2, # 1900-1909
	0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977, # 1910-1919
	0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970, # 1920-1929
	0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950, # 1930-1939
	0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557, # 1940-1949
	0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0, # 1950-1959
	0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0, # 1960-1969
	0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6, # 1970-1979
	0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570, # 1980-1989
	0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0, # 1990-1999
	0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5, # 2000-2009
	0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930, # 2010-2019
	0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530, # 2020-2029
	0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45, # 2030-2039
	0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0, # 2040-2049
	0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0, # 2050-2059
	0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4, # 2060-2069
	0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0, # 2070-2079
	0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160, # 2080-2089
	0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252, # 2090-2099
	0x0d520, # 2100
]

const _SOLAR_MONTH_DAYS: Array = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

func _leap_month(y: int) -> int:
	return _LUNAR_INFO[y - 1900] & 0xf

func _leap_days(y: int) -> int:
	if _leap_month(y) != 0:
		return 30 if (_LUNAR_INFO[y - 1900] & 0x10000) != 0 else 29
	return 0

func _month_days(y: int, m: int) -> int:
	return 30 if (_LUNAR_INFO[y - 1900] & (0x10000 >> m)) != 0 else 29

func _year_days(y: int) -> int:
	var sum := 348
	var i := 0x8000
	while i > 0x8:
		if (_LUNAR_INFO[y - 1900] & i) != 0:
			sum += 1
		i >>= 1
	return sum + _leap_days(y)

func _is_solar_leap(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)

func _solar_month_days(y: int, m: int) -> int:
	if m == 2:
		return 29 if _is_solar_leap(y) else 28
	return _SOLAR_MONTH_DAYS[m - 1]

# Days from 1900-01-31 (offset 0) to the given Gregorian date
func _solar_to_offset(sy: int, sm: int, sd: int) -> int:
	var total := 0
	for y in range(1900, sy):
		total += 366 if _is_solar_leap(y) else 365
	for m in range(1, sm):
		total += _solar_month_days(sy, m)
	total += sd - 1
	return total - 30  # Jan 31 = index 30 from Jan 1

# Convert day offset (from 1900-01-31) back to Gregorian date
func _offset_to_solar(offset: int) -> Dictionary:
	var total := offset + 30  # 0-indexed days from 1900-01-01
	var y := 1900
	while y < 2101:
		var yd := 366 if _is_solar_leap(y) else 365
		if total < yd:
			break
		total -= yd
		y += 1
	var m := 1
	while m <= 12:
		var md := _solar_month_days(y, m)
		if total < md:
			break
		total -= md
		m += 1
	return {"year": y, "month": m, "day": total + 1}

# Convert Gregorian date → Lunar date
# Returns: {year, month, day, is_leap}
func solar_to_lunar(sy: int, sm: int, sd: int) -> Dictionary:
	if sy < 1900 or sy > 2100:
		return {"year": sy, "month": sm, "day": sd, "is_leap": false}

	var offset := _solar_to_offset(sy, sm, sd)

	var lunar_year := 1900
	while lunar_year < 2101:
		var yd := _year_days(lunar_year)
		if offset < yd:
			break
		offset -= yd
		lunar_year += 1

	var leap := _leap_month(lunar_year)
	var is_leap := false
	var lunar_month := 1

	for m in range(1, 13):
		var md := _month_days(lunar_year, m)
		if offset < md:
			lunar_month = m
			break
		offset -= md
		if m == leap and leap != 0:
			var ld := _leap_days(lunar_year)
			if offset < ld:
				is_leap = true
				lunar_month = m
				break
			offset -= ld

	return {"year": lunar_year, "month": lunar_month, "day": offset + 1, "is_leap": is_leap}

# Convert Lunar date → Gregorian date
# Returns: {year, month, day}
func lunar_to_solar(ly: int, lm: int, ld: int, is_leap: bool = false) -> Dictionary:
	if ly < 1900 or ly > 2100:
		return {"year": ly, "month": lm, "day": ld}

	var offset := 0
	for y in range(1900, ly):
		offset += _year_days(y)

	var leap := _leap_month(ly)
	for m in range(1, lm):
		offset += _month_days(ly, m)
		if m == leap and leap != 0:
			offset += _leap_days(ly)

	if is_leap and lm == leap:
		offset += _month_days(ly, lm)

	offset += ld - 1
	return _offset_to_solar(offset)
