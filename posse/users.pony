use "net"
use "promises"
use "collections"


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

primitive _UserStateConnected fun apply(): String => "UserStateConnected" fun hash(): USize => apply().hash()
primitive _UserStateNickKnown fun apply(): String => "UserStateNickKnown" fun hash(): USize => apply().hash()
primitive _UserStateUserKnown fun apply(): String => "UserStateUserKnown" fun hash(): USize => apply().hash()
primitive _UserStateRegistered fun apply(): String => "UserStateRegistered" fun hash(): USize => apply().hash()
primitive _UserStateDisconnected fun apply(): String => "UserStateDisconnected" fun hash(): USize => apply().hash()
primitive _UserStateCapabilityList fun apply(): String => "UserStateCapabilityList" fun hash(): USize => apply().hash()
primitive _UserStateCapabilitiesNickKnown fun apply(): String => "UserStateapabilitiesNickKnown" fun hash(): USize => apply().hash()
primitive _UserStateCapabilitiesUserKnown fun apply(): String => "UserStateapabilitiesUserKnown" fun hash(): USize => apply().hash()

type _UserState is (
		  _UserStateConnected | _UserStateCapabilityList
		| _UserStateNickKnown | _UserStateCapabilitiesNickKnown
		| _UserStateUserKnown | _UserStateCapabilitiesUserKnown
		| _UserStateRegistered
		| _UserStateDisconnected
		)

primitive _UserStates
	fun only(states: Array[_UserState] val): Array[_UserState] val => states
	fun all(): Array[_UserState] val => [_UserStateConnected; _UserStateNickKnown; _UserStateCapabilitiesNickKnown; _UserStateCapabilitiesUserKnown; _UserStateRegistered; _UserStateDisconnected; _UserStateCapabilityList]
	fun all_but(states: Array[_UserState] val): Array[_UserState] val => all()

interface ClientCommand
	fun command(): String val
		"""
		String containing the command that the user will have sent
		"""
	fun user_states(): Array[_UserState] val
		"""
		Array of states where this command is valid. If there are conditions on the validity of certain states, then those checks should be done in the `handle` function.
		"""
	fun handle(user: User ref, msg: Message)
		"""
		Handle the message in whatever way is appropriate.
		"""

class val PingCommand is ClientCommand
	fun command(): String val => "PING"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		user.do_ping(msg)

class val PongCommand is ClientCommand
	fun command(): String val => "PONG"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		user.do_pong(msg)

class val PrivmsgCommand is ClientCommand
	fun command(): String val => "PRIVMSG"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) =>
		user.do_privmsg(msg)

class val UserCommand is ClientCommand
	fun command(): String val => "USER"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateRegistered; _UserStateDisconnected])
	fun handle(user: User ref, msg: Message) => user.do_user(msg)

class val NickCommand is ClientCommand
	fun command(): String val => "NICK"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) => user.do_nick(msg)

class val JoinCommand is ClientCommand
	fun command(): String val => "JOIN"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) => user.do_join(msg)

class val PartCommand is ClientCommand
	fun command(): String val => "PART"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) => user.do_part(msg)

class val TopicCommand is ClientCommand
	fun command(): String val => "TOPIC"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) => user.do_topic(msg)

class val QuitCommand is ClientCommand
	fun command(): String val => "QUIT"
	fun user_states(): Array[_UserState] val => _UserStates.all()
	fun handle(user: User ref, msg: Message) => user.do_quit(msg)


class val BasicCommandsKey
	let state: _UserState
	let command: String val
	new val create(state': _UserState, command': String) =>
		state = state'
		command = command'
	fun hash(): USize => state().hash() + command.hash()
	fun eq(other: BasicCommandsKey): Bool => (other.state is state) and other.command.eq(command)
	fun ne(other: BasicCommandsKey): Bool => not eq(other)

class BasicCommands
	var commands: Map[BasicCommandsKey, ClientCommand val] ref = Map[BasicCommandsKey, ClientCommand val]()

	new create() =>
		add_allof(PingCommand)
		add_allof(PongCommand)
		add_allof(UserCommand)
		add_allof(NickCommand)
		add_allof(PrivmsgCommand)
		add_allof(JoinCommand)
		add_allof(PartCommand)
		add_allof(TopicCommand)
		add_allof(QuitCommand)

	fun ref add_allof(cmd: ClientCommand val) =>
		for s in cmd.user_states().values() do
			@printf[None]("Adding %s / %s\n".cstring(), cmd.command().cstring(), s.apply().cstring())
			commands.update(BasicCommandsKey(s, cmd.command()), cmd)
		end

	fun apply(state: _UserState, command: String): (ClientCommand val | None) =>
		let key = BasicCommandsKey(state, command)
		if commands.contains(key) then
			try commands.apply(key)? else None end
		else
			None
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

	let commands: BasicCommands = BasicCommands.create()

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
		out.print("current user state: " + _state.apply())

		let cmd: (ClientCommand val | None) = commands.apply(_state, msg.command)
		match cmd
		| let cmd': ClientCommand val =>
			out.print("--> found ClientCommand " + cmd'.command())
			cmd'.handle(this, msg)
		else
			out.print("--> invalid state/command: " + msg.command + " / " + _state.apply())
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

