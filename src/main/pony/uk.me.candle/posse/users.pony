use "net"
use "promises"

actor UserRegistry
	var users: Array[User] = Array[User]

	be add(user: User) =>
		users.push(user)
	
	be privmsg(user: User, msg: Message) =>
		for u in users.values() do
			u.with_data(recover {(nick, _u, _r, _h, _f)(msg, u) =>
				try
					if msg.params(0)? == nick then
						u.to_client(msg)
					end
				end
			} end )
		end

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
		host = IPAddrString(addr, false)

	be with_nick(p: Promise[String]) => p(nick)

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

	be to_client_with_nick(msg: Message) =>
		connection.write(msg.with_param_first(nick).string() + "\r\n")
	be to_client(msg: Message) =>
		connection.write(msg.string() + "\r\n")

	be do_join(msg: Message) =>
		registries.channels.join(this, msg.with_prefix(prefix()))

	be do_topic(msg: Message) =>
		registries.channels.update_topic(this, msg.with_prefix(prefix()))

	be do_privmsg(msg: Message) =>
		try
			let target = msg.params(0)?
			if target.substring(0, 1) == "#" then // TODO make this understand configurable channel prefix characters.
				registries.channels.privmsg(this, msg.with_prefix(prefix()))
			else
				registries.users.privmsg(this, msg.with_prefix(prefix()))
			end
		end

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
		let oldfull = full
		try
			nick = msg.params(0)?
		//else
			// TODO respond with error
		end
		out.print("new nick is: " + nick)
		//else
		//--- respond with 433
		//end

		if startup_sent then
			// TODO send the nick change message to all interested parties.
			to_client(Message(oldfull, "NICK", [], nick))
		end

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
			full = prefix()
			out.print("full: " + full)
			// need to add the nickname as the first paramater, and 'full' to the end of the trailing.
			let t: User tag = this
			if not startup_sent then
				registries.users.add(this)
				server.response_001(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
				server.response_002(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
				server.response_003(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
				server.response_004(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
				// users.register(t)
				startup_sent = true
			end

		end

