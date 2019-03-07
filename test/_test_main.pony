use "ponytest"
use "../posse"

actor Main is TestList
	new create(env: Env) =>
		PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		TestMessageParse.make().tests(test)
		TestMessage.make().tests(test)
