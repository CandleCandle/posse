use "net"
use "promises"

actor UserRegistry
	var users: Array[User] = Array[User]

	be add(user: User) =>
		users.push(user)

	be quit(user: User, msg: Message) =>
		try users.delete(users.find(user)?)? end

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

primitive _UserStateConnected fun apply(): String => "UserStateConnected"
primitive _UserStateNickKnown fun apply(): String => "UserStateNickKnown"
primitive _UserStateUserKnown fun apply(): String => "UserStateUserKnown"
primitive _UserStateRegistered fun apply(): String => "UserStateRegistered"
primitive _UserStateDisconnected fun apply(): String => "UserStateDisconnected"

type _UserState is ( _UserStateConnected | _UserStateNickKnown | _UserStateUserKnown | _UserStateRegistered | _UserStateDisconnected )

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

	var _state: _UserState = _UserStateConnected

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
		out.print("current user state: " + _state())
		// rebuild msg to add prefix.
		// dispatch to user/channel
		match _state
		| _UserStateRegistered =>
			match msg.command
			| "JOIN" => do_join(msg)
			| "PART" => do_part(msg)
			| "PRIVMSG" => do_privmsg(msg)
			| "TOPIC" => do_topic(msg)
			| "QUIT" => do_quit(msg)
			| "PING" => do_ping(msg)
			| "PONG" => do_pong(msg)
			end
		else
			match msg.command
			| "USER" => do_user(msg)
			| "NICK" => do_nick(msg)
			| "QUIT" => do_quit(msg)
			| "PING" => do_ping(msg)
			| "PONG" => do_pong(msg)
			end
		end

	fun ref prefix(): String =>
		nick + "!" + user + "@" + host

	be to_client_with_nick(msg: Message) =>
		connection.write(msg.with_param_first(nick).string() + "\r\n")
	be to_client(msg: Message) =>
		_to_client(msg)
	fun ref _to_client(msg: Message) =>
		connection.write(msg.string() + "\r\n")

	fun ref do_join(msg: Message) =>
		registries.channels.join(this, msg.with_prefix(prefix()))

	fun ref do_part(msg: Message) =>
		registries.channels.part(this, msg.with_prefix(prefix()))

	fun ref do_topic(msg: Message) =>
		registries.channels.update_topic(this, msg.with_prefix(prefix()))

	fun ref do_quit(msg: Message) =>
		registries.channels.quit(this, msg.with_prefix(prefix()))
		registries.users.quit(this, msg.with_prefix(prefix()))
		_state = _UserStateDisconnected
		connection.dispose()

	fun ref do_privmsg(msg: Message) =>
		try
			let target = msg.params(0)?
			if target.substring(0, 1) == "#" then // TODO make this understand configurable channel prefix characters.
				registries.channels.privmsg(this, msg.with_prefix(prefix()))
			else
				registries.users.privmsg(this, msg.with_prefix(prefix()))
			end
		end

	fun ref do_ping(msg: Message) =>
		_to_client(_ping_pong("PONG", msg))

	fun ref do_pong(msg: Message) =>
		_to_client(_ping_pong("PING", msg))

	fun _ping_pong(cmd: String, msg: Message): Message =>
		if (msg.trailing == "") then
			Message.create("", cmd, recover try [msg.params(0)?] else Array[String](0) end end, "")
		else
			Message.create("", cmd, recover Array[String](0) end, msg.trailing)
		end

	fun ref do_nick(msg: Message) =>
		//TODO if check_nick() then
		let oldfull = full
		try
			nick = msg.params(0)?
		end
		match _state
		| _UserStateConnected => _state = _UserStateNickKnown
		end
		out.print("new nick is: " + nick)

		match _state
		| _UserStateRegistered =>
			// TODO send the nick change message to all interested parties.
			to_client(Message(oldfull, "NICK", [], nick))
		end

	fun ref do_user(msg: Message) =>
		try
			user = msg.params(0)?
			real = msg.trailing
		end
		out.print("user is: " + nick)
		out.print("real is: " + real)
		match _state
		| _UserStateNickKnown =>
			registries.users.add(this)
			_state = _UserStateRegistered
			send_initial_stats()
		end

	fun ref send_initial_stats() =>
		let t: User tag = this
		server.response_001(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
		server.response_002(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
		server.response_003(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)
		server.response_004(recover {(m: Message)(t) => t.to_client(m.with_param_first(nick)) } end)

