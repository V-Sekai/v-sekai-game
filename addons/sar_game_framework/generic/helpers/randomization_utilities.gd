@tool
class_name RandomizationUtilities

## This class contains helper functions designed to help with tasks
## which involve random number generation.

# Custom base64 table needed for directories
const _BASE_64_TABLE = [
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"_",
	"-",
]

###

## Returns a unique id string comprising of characters from the base64_table
## using a random number generator to determine each character.
## It will will first call randomize() before generating the table.
## p_size is the amount of characters to generate in the string.
static func generate_insecure_unique_id(p_size: int) -> String:
	var string: String = ""

	randomize()

	for _i in range(0, p_size):
		string += _BASE_64_TABLE[randi() % 64]

	return string
