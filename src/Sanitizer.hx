import Kanaconv;

class Sanitizer {
	public static function sanitize(input:String):String {
		if (input == null || input == "") {
			trace("sanitizer input is null or empty -- returning input: " + input);
			return input;
		}

		// Convert full-width characters to half-width
		var convertedPayee = Kanaconv.toFullWidth(input);
		convertedPayee = Kanaconv.fullWidthRomajiToHalf(convertedPayee);

		// Add space before /iD
		convertedPayee = StringTools.replace(convertedPayee, "/iD", " /iD");

		// do the same for /NFC
		convertedPayee = StringTools.replace(convertedPayee, "/NFC", " /NFC");

		// strip ALL consecutive spaces, so "   " becomes " "
		while (StringTools.contains(convertedPayee, "  ")) {
			convertedPayee = StringTools.replace(convertedPayee, "  ", " ");
		}

		// trim leading and trailing spaces
		convertedPayee = StringTools.trim(convertedPayee);

		return convertedPayee;
	}
}
