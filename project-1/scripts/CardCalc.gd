extends Node

const _ZODIAC_ANIMALS: Array = ["鼠","牛","虎","兔","龍","蛇","馬","羊","猴","雞","狗","豬"]

# 生肖 → 牌卡代號
const _CZ_TO_CARD: Dictionary = {
	"鼠": "BK", "牛": "GQ", "虎": "PB", "兔": "RK",
	"龍": "BQ", "蛇": "GG", "馬": "PK", "羊": "RQ",
	"猴": "BB", "雞": "GK", "狗": "PQ", "豬": "RG",
}

# 星座 → 牌卡代號
const _WZ_TO_CARD: Dictionary = {
	"天蠍座": "RK", "巨蟹座": "RQ", "雙魚座": "RG",
	"水瓶座": "BK", "天秤座": "BQ", "雙子座": "BB",
	"獅子座": "PK", "牡羊座": "PQ", "射手座": "PB",
	"金牛座": "GK", "摩羯座": "GQ", "處女座": "GG",
}

# 牌卡代號 → 圖片路徑
const _CARD_IMAGE: Dictionary = {
	"RK": "res://assets/images/PinkKing.png",
	"RQ": "res://assets/images/PinkQreen.png",
	"RG": "res://assets/images/PinkGril.png",
	"BK": "res://assets/images/BlueKing.png",
	"BQ": "res://assets/images/BlueQreen.png",
	"BB": "res://assets/images/BlueBoy.png",
	"PK": "res://assets/images/PurpleKing.png",
	"PQ": "res://assets/images/PurpleQreen.png",
	"PB": "res://assets/images/PurpleBoy.png",
	"GK": "res://assets/images/GreenKing.png",
	"GQ": "res://assets/images/GreenQreen.png",
	"GG": "res://assets/images/GreenGril.png",
}

# 生命靈數 → 大數牌卡（NUN/LUN）
const _LPN_UPPER_TO_CARD: Dictionary = {
	1: "PK", 2: "BQ", 3: "BB", 4: "GK", 5: "PB",
	6: "RQ", 7: "RK", 8: "GQ", 9: "BK",
}

# 生命靈數 → 小數牌卡（NLN/LLN）
const _LPN_LOWER_TO_CARD: Dictionary = {
	1: "PQ", 2: "RG", 3: "BB", 4: "RQ", 5: "PB",
	6: "GG", 7: "GG", 8: "RK", 9: "RG",
}

func get_lpn_upper_texture(number: int) -> Texture2D:
	return get_card_texture(_LPN_UPPER_TO_CARD.get(number, ""))

func get_lpn_lower_texture(number: int) -> Texture2D:
	return get_card_texture(_LPN_LOWER_TO_CARD.get(number, ""))

func get_card_texture(code: String) -> Texture2D:
	var path: String = _CARD_IMAGE.get(code, "")
	if path == "":
		return null
	return load(path) as Texture2D

func get_cz_card_texture(zodiac_animal: String) -> Texture2D:
	return get_card_texture(_CZ_TO_CARD.get(zodiac_animal, ""))

func get_wz_card_texture(zodiac_sign: String) -> Texture2D:
	return get_card_texture(_WZ_TO_CARD.get(zodiac_sign, ""))

const _WESTERN_ZODIAC: Array = [
	{"name": "摩羯座", "month": 1,  "day": 1},
	{"name": "水瓶座", "month": 1,  "day": 20},
	{"name": "雙魚座", "month": 2,  "day": 19},
	{"name": "牡羊座", "month": 3,  "day": 21},
	{"name": "金牛座", "month": 4,  "day": 20},
	{"name": "雙子座", "month": 5,  "day": 21},
	{"name": "巨蟹座", "month": 6,  "day": 22},
	{"name": "獅子座", "month": 7,  "day": 23},
	{"name": "處女座", "month": 8,  "day": 23},
	{"name": "天秤座", "month": 9,  "day": 23},
	{"name": "天蠍座", "month": 10, "day": 24},
	{"name": "射手座", "month": 11, "day": 22},
	{"name": "摩羯座", "month": 12, "day": 22},
]

# 生肖：輸入年份，回傳生肖名稱
func get_chinese_zodiac(year: int) -> String:
	return _ZODIAC_ANIMALS[(year - 1900) % 12]

# 星座：輸入月、日，回傳星座名稱
func get_western_zodiac(month: int, day: int) -> String:
	var result := "摩羯座"
	for i in range(_WESTERN_ZODIAC.size() - 1, -1, -1):
		var entry: Dictionary = _WESTERN_ZODIAC[i]
		if month > entry["month"] or (month == entry["month"] and day >= entry["day"]):
			result = entry["name"]
			break
	return result

# 生命靈數：輸入年月日，回傳 1~9
func get_life_path_number(year: int, month: int, day: int) -> int:
	var digits := str(year) + str(month) + str(day)
	var total := 0
	for ch in digits:
		total += int(ch)
	while total > 9:
		var next := 0
		while total > 0:
			next += total % 10
			total /= 10
		total = next
	return total
