import utest.Test;
import utest.Assert;
import utest.Runner;
import utest.ui.Report;
import Kanaconv;

class KanaconvTest extends Test {
	static function main() {
		var runner = new Runner();
		runner.addCase(new KanaconvTest());

		// Add reporting to see test results
		Report.create(runner);

		// Run tests and get results
		runner.run();
	}

	public function testToFullWidthHalfWidthKatakana() {
		var input = "ｱｲｳｴｵ";
		var expected = "アイウエオ";
		Assert.equals(expected, Kanaconv.toFullWidth(input));
	}

	public function testToFullWidthNonKana() {
		var input = "ABC123";
		var expected = "ABC123";
		Assert.equals(expected, Kanaconv.toFullWidth(input));
	}

	public function testToFullWidthEmptyString() {
		Assert.equals("", Kanaconv.toFullWidth(""));
	}

	public function testToFullWidthBoundaryKatakana() {
		Assert.equals("ヲン", Kanaconv.toFullWidth("ｦﾝ"));
	}

	public function testFullWidthRomajiToHalfUppercase() {
		var input = "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ";
		var expected = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testFullWidthRomajiToHalfLowercase() {
		var input = "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ";
		var expected = "abcdefghijklmnopqrstuvwxyz";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testFullWidthRomajiToHalfNumbers() {
		var input = "０１２３４５６７８９";
		var expected = "0123456789";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testFullWidthRomajiToHalfSymbols() {
		var input = "！＠＃＄％＾＆＊（）";
		var expected = "!@#$%^&*()";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testFullWidthRomajiToHalfMixed() {
		var input = "Ｈｅｌｌｏ　１２３！";
		var expected = "Hello 123!";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testFullWidthRomajiToHalfEmptyString() {
		Assert.equals("", Kanaconv.fullWidthRomajiToHalf(""));
	}

	public function testFullWidthRomajiToHalfNonConvertibleChars() {
		var input = "あいうえお１２３ＡＢＣ";
		var expected = "あいうえお123ABC";
		Assert.equals(expected, Kanaconv.fullWidthRomajiToHalf(input));
	}

	public function testSanitizeWithSpecialCharacters() {
		var input = "ｼﾞｬﾙｺｸｻｲｾﾝ/ｱｯﾌﾟﾙﾍﾟｲ ";
		var expected = "ジャルコクサイセン/アップルペイ ";
		Assert.equals(expected, Kanaconv.toFullWidth(input));
	}
}
