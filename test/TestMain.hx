import utest.Runner;
import utest.ui.Report;

class TestMain {
	static function main() {
		var runner = new Runner();

		// Add all test cases
		runner.addCase(new KanaconvTest());
		runner.addCase(new SanitizerTest());

		// Setup reporting
		Report.create(runner);

		// Run all tests
		runner.run();
	}
}
