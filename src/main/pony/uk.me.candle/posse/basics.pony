use "net"
use "time"
use "collections"

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
	var channels: Map[String, Channel] = Map[String, Channel]

	be join(user: User, msg: Message) =>
		try
			let channel_name = msg.params(0)?
			if not channels.contains(channel_name) then
				channels(channel_name) = Channel(channel_name)
			end
			channels(channel_name)?.join(user, msg)
		else
			user.to_client(Message("", "461", [], "Not enough parameters"))
		end

	be update_topic(user: User, msg: Message) =>
		try
			let channel_name = msg.params(0)?
			try
				channels(channel_name)?.update_topic(user, msg)
			else
				user.to_client(Message("", "403", [channel_name], "no such channel"))
			end
		end

//	be users(users' 


actor UserRegistry
	let channels: ChannelRegistry
	
	new create(channels': ChannelRegistry) =>
		channels = channels'

	be privmsg(user: User, msg: Message) =>
		// if <target>.startsWith('#') delegate to channel registry;
		// otherwise look for the user here and send.
		None

// actor ServerRegistry


actor Channel
	let users: Array[User] = Array[User].create()
	let name: String
	var topic: String = ""

	new create(name': String) =>
		name = name'

	be join(user: User, msg: Message) =>
		// before "joining": RPL_TOPIC
		if topic.size() > 0 then
			user.to_client(Message("posse", "332", [name], topic.clone())) // RPL_TOPIC
		else
			user.to_client(Message("posse", "331", [name], "")) // RPL_NOTOPIC
		end

		users.push(user)
		// after "joining": RPL_NAMREPLY so that this user is included in the reply.
		// should join names to reduce the number of messages sent.

		for u in users.values() do
			u.with_data(
				recover {(nick, _a, _b, _c, _d)(user) =>
					user.to_client(Message("", "353", [name], nick)) // RPL_NAMREPLY
				} end)
			u.with_data(
				recover {(_n, _u, _r, _h, full)(user, u, name) =>
					user.with_data(
						recover {(_n', _u', _r', _h', full')(u, name) =>
							u.to_client(Message(full', "JOIN", [name], ""))
						} end)
				} end)
		end
		user.to_client(Message("", "366", [name], "")) // RPL_ENDOFNAMES

	be update_topic(user: User, msg: Message) =>
		topic = msg.trailing
		for u in users.values() do
			u.to_client(Message("", "332", [name], topic.clone()))
		end

	be privmsg(msg: Message) =>
		"""
		"""
		//users.foreach(e -> e.send_msg(msg))

actor User
	let out: OutStream
	let connection: TCPConnection
	let registries: Registries
	let server: ServerStats
	var nick: String = ""
	var user: String = ""
	var real: String = ""
	var host: String
	var full: String = ""
	var startup_sent: Bool = false

	new create(out': OutStream, connection': TCPConnection, addr:NetAddress, registries': Registries, server': ServerStats) =>
		out = out'
		connection = connection'
		registries = registries'
		server = server'
		host = IPAddrString(addr)

	be with_data(callback: {(String, String, String, String, String)} iso) =>
		"""
		nick, user, real, host, full
		"""
		callback(nick, user, real, host, full)

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
		| "JOIN" => do_join(msg)
		| "PRIVMSG" => do_privmsg(msg)
		| "TOPIC" => do_topic(msg)
//		| "QUIT" => do_quit(msg)
		end
	
	fun ref prefix(): String =>
		nick + "!" + user + "@" + host

	be to_client(msg: Message) =>
		connection.write(msg.string() + "\r\n")

	be do_join(msg: Message) =>
		registries.channels.join(this, msg.with_prefix(prefix()))

	be do_topic(msg: Message) =>
		registries.channels.update_topic(this, msg.with_prefix(prefix()))

	be do_privmsg(msg: Message) =>
		registries.users.privmsg(this, msg)

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
			if not startup_sent then
				server.response_001(recover {(m: Message)(t) => t.to_client(m)} end)
				server.response_002(recover {(m: Message)(t) => t.to_client(m)} end)
				server.response_003(recover {(m: Message)(t) => t.to_client(m)} end)
				server.response_004(recover {(m: Message)(t) => t.to_client(m)} end)
				// users.register(t)
				startup_sent = true
			end

		end

