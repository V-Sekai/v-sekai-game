@tool
class_name SarNetworkUtilities

## This class contains helper functions designed for dealing with 
## networking code.

## Extract query parameter value from url using a key
static func extract_query_param(url: String, key: String) -> String:
		var idx := url.find("?")
		if idx == -1:
			return ""  # no query params at all

		# Strip off '?'
		var query := url.substr(idx + 1, url.length() - idx - 1)

		var pairs := query.split("&")

		for part in pairs:
			var pair := part.split("=")
			if pair.size() != 2:
				push_warning("Invalid pair detected. Url query may be parsed incorrectly")
			if pair.size() == 2 and pair[0] == key:
				return pair[1]

		return ""
