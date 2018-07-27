use "net"
use "time"

actor ServerStats
	let server_name: String
	let version: String
	let user_registry: UserRegistry
	let channel_registry: ChannelRegistry
	let start_time: PosixDate

	new create(server_name': String, version': String, user_registry': UserRegistry, channel_registry': ChannelRegistry) =>
		server_name = server_name'
		version = version'
		user_registry = user_registry'
		channel_registry = channel_registry'
		let now = Time.now()
		start_time = PosixDate.create(now._1, now._2)

	be response_001(callback: {(Message)} iso) =>
		callback(Message.create(server_name, "001", recover Array[String](0) end, ""))

	be response_002(callback: {(Message)} iso) =>
		callback(Message.create(server_name, "002", recover Array[String](0) end, "Your host is " + server_name + ", running version Posse " + version))

	be response_003(callback: {(Message)} iso) =>
		callback(Message.create(server_name, "003", recover Array[String](0) end, "Server created " + start_time.format("%FT%T%z")))

	be response_004(callback: {(Message)} iso) =>
		// [server_name, version, ??, ??]
		callback(Message.create(server_name, "004", recover [server_name; version; "??"; "??"] end, ""))

	be response_005(callback: {(Array[Message] val)} iso) =>
		// MAXCHANNELS=100 CHANLIMIT=#:100 MAXNICKLEN=30 NICKLEN=30 CHANNELLEN=32 TOPICLEN=307 KICKLEN=307 AWAYLEN=307
		// CHANTYPES=# MAXTARGETS=20
		callback(recover [
			Message.create(server_name, "005", recover Array[String](0) end, "are supported by this server")
			Message.create(server_name, "005", recover Array[String](0) end, "are supported by this server")
		] end)

actor ChannelRegistry
	var users: None = None//UserRegistry

//	be users(users' 


actor UserRegistry
	let channels: ChannelRegistry
	
	new create(channels': ChannelRegistry) =>
		channels = channels'


// actor ServerRegistry


actor Channel
	let users: Array[User] = Array[User].create()

	be privmsg(msg: Message) =>
		"""
		"""
		//users.foreach(e -> e.send_msg(msg))

actor User
	let out: OutStream
	let connection: TCPConnection
	let users: UserRegistry
	let server: ServerStats
	var nick: String = ""
	var user: String = ""
	var real: String = ""
	var host: String
	var full: String = ""

	new create(out': OutStream, connection': TCPConnection, addr:NetAddress, users': UserRegistry, server': ServerStats) =>
		out = out'
		connection = connection'
		users = users'
		server = server'
		host = IPAddrString(addr)

	be connect_timeout() =>
		"""
		"""
		// on a timer,
		// when fired, check user has connected properly.
		// NICK sent.
		// USER sent.
		// on timeout, close connection.
		// unregister everything.

	be ping() =>
		"""
		"""
		// on a timer, try ping expect pong, on fail, unregister, send QUIT/? to channels.
		// stuff

	be from_client(msg: Message) =>
		// rebuild msg to add prefix.
		// dispatch to user/channel
		match msg.command
		| "NICK" => do_nick(msg)
		| "USER" => do_user(msg)
		| "PING" => do_ping(msg)
		| "PONG" => do_pong(msg)
		end

	be to_client(msg: Message) =>
		connection.write(msg.string() + "\r\n")

	be do_ping(msg: Message) =>
		to_client(_ping_pong("PONG", msg))

	be do_pong(msg: Message) =>
		to_client(_ping_pong("PING", msg))

	fun _ping_pong(cmd: String, msg: Message): Message =>
		if (msg.trailing == "") then
			Message.create("", cmd, recover try [msg.params(0)?] else Array[String](0) end end, "")
		else
			Message.create("", cmd, recover Array[String](0) end, msg.trailing)
		end

	be do_nick(msg: Message) =>
		//TODO if check_nick() then
		try
			nick = msg.params(0)?
		//else
			// TODO respond with error
		end
		out.print("new nick is: " + nick)
		//else
		//--- respond with 433
		//end
		check_logged_in_correctly_and_send_initial_stuff()

	be do_user(msg: Message) =>
		try
			user = msg.params(0)?
			real = msg.trailing
		// else TODO respond with error.
		end
		out.print("user is: " + nick)
		out.print("real is: " + real)
		check_logged_in_correctly_and_send_initial_stuff()

	fun ref check_logged_in_correctly_and_send_initial_stuff() =>
		// TODO rename.
		if (nick != "") and (real != "") then
			full = nick + "!" + user + "@" + host
			out.print("full: " + full)
			// need to add the nickname as the first paramater, and 'full' to the end of the trailing.
			let t: User tag = this
			server.response_001(recover {(m: Message)(t) => t.to_client(m)} end)
			server.response_002(recover {(m: Message)(t) => t.to_client(m)} end)
			server.response_003(recover {(m: Message)(t) => t.to_client(m)} end)
			server.response_004(recover {(m: Message)(t) => t.to_client(m)} end)

		end

