import utest.Test;
import utest.Assert;
import utest.Runner;
import utest.ui.Report;
import Sanitizer;

class SanitizerTest extends Test {
	static function main() {
		var runner = new Runner();
		runner.addCase(new SanitizerTest());
		Report.create(runner);
		runner.run();
	}

	public function testSanitizeFullWidthToHalf() {
		var input = "Ｈｅｌｌｏ　Ｗｏｒｌｄ";
		var expected = "Hello World";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testSanitizeAddSpaceBeforeID() {
		var input = "Payment/iD";
		var expected = "Payment /iD";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testSanitizeConsecutiveSpaces() {
		var input = "Hello    World   Test";
		var expected = "Hello World Test";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testSanitizeCombinedOperations() {
		var input = "Ｐａｙｍｅｎｔ　　　/iD";
		var expected = "Payment /iD";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testSanitizeEmptyString() {
		Assert.equals("", Sanitizer.sanitize(""));
	}

	public function testSanitizeWithNumbers() {
		var input = "Ｐａｙｍｅｎｔ１２３　　/iD";
		var expected = "Payment123 /iD";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testSanitizeWithSpecialCharacters() {
		var input = "ｼﾞｬﾙｺｸｻｲｾﾝ/ｱｯﾌﾟﾙﾍﾟｲ ";
		var expected = "ジャルコクサイセン/アップルペイ";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}

	public function testBookingExample1() {
		var input = "ＲＯＹＡＬＴＨＡＬＩ";
		var expected = "ROYALTHALI";
		Assert.equals(expected, Sanitizer.sanitize(input));
	}
}
