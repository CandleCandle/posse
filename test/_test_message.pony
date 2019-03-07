use "ponytest"
use "../posse"

actor TestMessage is TestList
	new create(env: Env) =>
		PonyTest(env, this)

	new make() => None

	fun tag tests(test: PonyTest) =>
		let tests' = _all_tests()
		while tests'.size() > 0 do
			try test(tests'.pop()?) end
		end

	fun tag _all_tests(): Array[UnitTest iso] =>
		[as UnitTest iso:

object iso is UnitTest
	fun name(): String => "1"
	fun apply(h: TestHelper) =>
		None
end

        ]