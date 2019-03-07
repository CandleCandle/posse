use "ponytest"
use "../posse"

actor TestMessageParse is TestList
	new create(env: Env) =>
		PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_TestCreateStringPing)
		test(_TestCreateStringPong)
		_TestMessageParse.make().tests(test)

actor _TestMessageParse is TestList
	new create(env: Env) =>
		PonyTest(env, this)
	new make() => None

	fun tag tests(test: PonyTest) =>
		test(_TestGenericRaw("notice / raw", _Examples().notice, _Examples().notice))
		test(_TestGenericString("notice / string", _Examples().notice, _Examples().notice))
		test(_TestGenericPrefix("notice / prefix", "", _Examples().notice))
		test(_TestGenericCommand("notice / command", "NOTICE", _Examples().notice))
		test(_TestGenericParams("notice / params", recover ["AUTH"; "*** Found your hostname, welcome back"] end, _Examples().notice))
		test(_TestGenericTrailing("notice / trailing", "*** Found your hostname, welcome back", _Examples().notice))

		test(_TestGenericRaw("nick_in_use / raw", _Examples().nick_in_use, _Examples().nick_in_use))
		test(_TestGenericString("nick_in_use / string", _Examples().nick_in_use, _Examples().nick_in_use))
		test(_TestGenericPrefix("nick_in_use / prefix", "irc.example.com", _Examples().nick_in_use))
		test(_TestGenericCommand("nick_in_use / command", "433", _Examples().nick_in_use))
		test(_TestGenericParams("nick_in_use / params", recover ["*"; "SomeNick"; "Nickname is already in use."] end, _Examples().nick_in_use))
		test(_TestGenericTrailing("nick_in_use / trailing", "Nickname is already in use.", _Examples().nick_in_use))

		test(_TestGenericRaw("ping / raw", _Examples().ping, _Examples().ping))
		test(_TestGenericString("ping / string", _Examples().ping, _Examples().ping))
		test(_TestGenericPrefix("ping / prefix", "", _Examples().ping))
		test(_TestGenericCommand("ping / command", "PING", _Examples().ping))
		test(_TestGenericParams("ping / params", recover ["uuid"] end, _Examples().ping))
		test(_TestGenericTrailing("ping / trailing", "uuid", _Examples().ping))

		test(_TestGenericRaw("ping param / raw", _Examples().ping_param, _Examples().ping_param))
		test(_TestGenericString("ping param / string", _Examples().ping_param, _Examples().ping_param))
		test(_TestGenericPrefix("ping param / prefix", "", _Examples().ping_param))
		test(_TestGenericCommand("ping param / command", "PING", _Examples().ping_param))
		test(_TestGenericParams("ping param / params", recover ["uuid"] end, _Examples().ping_param))
		test(_TestGenericTrailing("ping param / trailing", "", _Examples().ping_param))

		test(_TestGenericRaw("privmsg / raw", _Examples.privmsg, _Examples.privmsg))
		test(_TestGenericString("privmsg / string", _Examples.privmsg, _Examples.privmsg))
		test(_TestGenericPrefix("privmsg / prefix", "nick!user@some.host-name", _Examples().privmsg))
		test(_TestGenericCommand("privmsg / command", "PRIVMSG", _Examples().privmsg))
		test(_TestGenericParams("privmsg / params", recover ["#channel"; "message content"] end, _Examples().privmsg))
		test(_TestGenericTrailing("privmsg / trailing", "message content", _Examples().privmsg))

		test(_TestGenericRaw("privmsg2 / raw", _Examples.privmsg2, _Examples.privmsg2))
		test(_TestGenericString("privmsg2 / string", _Examples.privmsg2, _Examples.privmsg2))
		test(_TestGenericPrefix("privmsg2 / prefix", "Candle!Candle@Clk-481F8504", _Examples().privmsg2))
		test(_TestGenericCommand("privmsg2 / command", "PRIVMSG", _Examples().privmsg2))
		test(_TestGenericParams("privmsg2 / params", recover ["#bots"; "ACTION drops #bots from pirb's autojoin list."] end, _Examples().privmsg2))
		test(_TestGenericTrailing("privmsg2 / trailing", "ACTION drops #bots from pirb's autojoin list.", _Examples().privmsg2))

		test(_TestGenericRaw("tagged_privmsg / raw", _Examples.tagged_privmsg, _Examples.tagged_privmsg))
		test(_TestGenericString("tagged_privmsg / string", "@ccc;aaa=bbb;example.com/ddd=eee :nick!user@some.host-name PRIVMSG #channel :message content", _Examples.tagged_privmsg)) // XXX hash order is likely to change. should use a different test
		test(_TestGenericPrefix("tagged_privmsg / prefix", "nick!user@some.host-name", _Examples().tagged_privmsg))
		test(_TestGenericCommand("tagged_privmsg / command", "PRIVMSG", _Examples().tagged_privmsg))
		test(_TestGenericParams("tagged_privmsg / params", recover ["#channel"; "message content"] end, _Examples().tagged_privmsg))
		test(_TestGenericTrailing("tagged_privmsg / trailing", "message content", _Examples().tagged_privmsg))
		test(_TestGenericTags("tagged_privmsg / tags / aaa", "aaa", "bbb", _Examples().tagged_privmsg))
		test(_TestGenericTags("tagged_privmsg / tags / ccc", "ccc", None, _Examples().tagged_privmsg))
		test(_TestGenericTags("tagged_privmsg / tags / example.com/ddd", "example.com/ddd", "eee", _Examples().tagged_privmsg))


class val _Examples
	let notice: String = "NOTICE AUTH :*** Found your hostname, welcome back"
	let nick_in_use: String = ":irc.example.com 433 * SomeNick :Nickname is already in use."
	let ping: String = "PING :uuid"
	let ping_param: String = "PING uuid"
	let privmsg: String = ":nick!user@some.host-name PRIVMSG #channel :message content"
	let privmsg2: String = ":Candle!Candle@Clk-481F8504 PRIVMSG #bots :ACTION drops #bots from pirb's autojoin list."
	let tagged_privmsg: String = "@aaa=bbb;ccc;example.com/ddd=eee :nick!user@some.host-name PRIVMSG #channel :message content"

	fun val apply(): _Examples =>
		this

class Dump
	fun apply(h: TestHelper, m: Message) =>
		h.log(m.a.size().string() +  " captured groups")
		for (idx, item) in m.a.pairs() do
			h.log("cap: " + idx.string() + ": " + item)
		end
		h.log("raw: " + m.raw)
		h.log("command: " + m.command)
		for (idx, item) in m.params.pairs() do
			h.log("param: " + idx.string() + ": " + item)
		end
		h.log("tags:")
		for (k, v) in m.tags.pairs() do
			match v
			| let v': String => h.log("  " + k + " => " + v')
			| let v'': None => h.log("  " + k + " *> (None)")
			end
		end

class iso _TestCreateStringPing is UnitTest
	fun name(): String => "create - string / ping"
	fun apply(h: TestHelper) =>
		let m = Message.create("", "PING", recover Array[String](0) end, "some data")
		Dump(h, m)
		h.assert_eq[String]("PING :some data", m.string())

class iso _TestCreateStringPong is UnitTest
	fun name(): String => "create - string / pong"
	fun apply(h: TestHelper) =>
		let m = Message.create("", "PONG", recover ["data"] end, "")
		Dump(h, m)
		h.assert_eq[String]("PONG data", m.string())

class iso _TestPrependParam is UnitTest
	fun name(): String => "prepend param / pong"
	fun apply(h: TestHelper) =>
		let m = Message.create("", "PONG", recover ["data"] end, "")
			.prepend_param("other")
		Dump(h, m)
		h.assert_eq[String]("PONG data other", m.string())

class iso _TestGenericRaw is UnitTest
	let nme: String
	let expected: String
	let input: String
	new iso create(nme': String, expected': String, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[String](expected, m.raw)

class iso _TestGenericPrefix is UnitTest
	let nme: String
	let expected: String
	let input: String
	new iso create(nme': String, expected': String, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[String](expected, m.prefix)

class iso _TestGenericCommand is UnitTest
	let nme: String
	let expected: String
	let input: String
	new iso create(nme': String, expected': String, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[String](expected, m.command)

class iso _TestGenericParams is UnitTest
	let nme: String
	let expected: Array[String] val
	let input: String
	new iso create(nme': String, expected': Array[String] val, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) ? =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[USize](expected.size(), m.params.size())
		for (k, v) in expected.pairs() do
			h.assert_eq[String](v, m.params(k)?)
		end

class iso _TestGenericTrailing is UnitTest
	let nme: String
	let expected: String
	let input: String
	new iso create(nme': String, expected': String, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[String](expected, m.trailing)


class iso _TestGenericString is UnitTest
	let nme: String
	let expected: String
	let input: String
	new iso create(nme': String, expected': String, input': String) =>
		nme = nme'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		h.assert_eq[String](expected, m.string())


class iso _TestGenericTags is UnitTest
	let nme: String
	let key: String
	let expected: (None | String )
	let input: String
	new iso create(nme': String, key': String, expected': (None | String), input': String) =>
		nme = nme'
		key = key'
		expected = expected'
		input = input'
	fun name(): String => nme
	fun apply(h: TestHelper) =>
		let m = Message.from_raw(input)
		Dump(h, m)
		try
			let f: (None | String) = m.tags.apply(key)?
			match expected
			| let e': None =>
				match f
				| let f': String => h.fail("Expected None, got a String " + f')
				end
			| let e'' : String =>
				match f
				| let f': None => h.fail("Expected a String: " + e'' + " got None.")
				| let f'': String =>
					h.assert_eq[String](e'', f'')
				end
			end
		else h.fail("missing key: " + key) end