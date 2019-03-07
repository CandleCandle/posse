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

primitive _UserStateConnected
	fun apply(): String => "UserStateConnected"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateNickKnown; _UserStateUserKnown; _UserStateCapabilityList; _UserStateDisconnected]
primitive _UserStateNickKnown
	fun apply(): String => "UserStateNickKnown"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateUserKnown; _UserStateRegistered; _UserStateDisconnected]
primitive _UserStateUserKnown
	fun apply(): String => "UserStateUserKnown"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateNickKnown; _UserStateRegistered; _UserStateDisconnected]
primitive _UserStateRegistered
	fun apply(): String => "UserStateRegistered"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateDisconnected]
primitive _UserStateDisconnected
	fun apply(): String => "UserStateDisconnected"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => []
primitive _UserStateCapabilityList
	fun apply(): String => "UserStateCapabilityList"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateCapabilitiesNickKnown; _UserStateCapabilitiesUserKnown; _UserStateDisconnected; _UserStateRegistered]
primitive _UserStateCapabilitiesNickKnown
	fun apply(): String => "UserStateCapabilitiesNickKnown"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateCapabilitiesUserKnown; _UserStateCapabilitiesNegotiated; _UserStateDisconnected; _UserStateRegistered]
primitive _UserStateCapabilitiesUserKnown
	fun apply(): String => "UserStateCapabilitiesUserKnown"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateCapabilitiesNickKnown; _UserStateCapabilitiesNegotiated; _UserStateDisconnected; _UserStateRegistered]
primitive _UserStateCapabilitiesNegotiated
	fun apply(): String => "_UserStateCapabilitiesNegotiated"
	fun hash(): USize => apply().hash()
	fun next(): Array[_UserState] => [_UserStateRegistered; _UserStateDisconnected; _UserStateRegistered]

type _UserState is (
		  _UserStateConnected | _UserStateCapabilityList
		| _UserStateNickKnown | _UserStateCapabilitiesNickKnown
		| _UserStateUserKnown | _UserStateCapabilitiesUserKnown
		| _UserStateCapabilitiesNegotiated
		| _UserStateRegistered
		| _UserStateDisconnected
		)

primitive CapabilityServerTime
	fun apply(): String => "server-time"
	fun hash(): USize => apply().hash()

type Capability is (
		CapabilityServerTime
		)

primitive _Capabilities
	fun all(): Array[Capability] val => [CapabilityServerTime]
	fun all_as_string(): Array[String] val =>
		let result: Array[String] iso = recover iso Array[String](all().size()) end
		for c in all().values() do
			result.push(c())
		end
		consume result
	fun from_string(str: String): ( Capability | None ) =>
		for c in all().values() do
			if c() == str then
				return c
			end
		end
		None


primitive _UserStates
	fun only(states: Array[_UserState] val): Array[_UserState] val => states
	fun all(): Array[_UserState] val => [_UserStateConnected; _UserStateNickKnown; _UserStateCapabilitiesNickKnown; _UserStateCapabilitiesUserKnown; _UserStateRegistered; _UserStateDisconnected; _UserStateCapabilityList]
	fun all_but(states: Array[_UserState] val): Array[_UserState] val => all()
	fun allowed(from: _UserState, to: _UserState): Bool =>
		from.next().contains(to)

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

primitive PingCommand is ClientCommand
	fun command(): String val => "PING"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		user.to_client(_create_pong(msg))
	fun tag _create_pong(msg: Message): Message =>
		if (msg.trailing == "") then
			Message.create("", "PONG", recover try [msg.params(0)?] else Array[String](0) end end, "")
		else
			Message.create("", "PONG", recover Array[String](0) end, msg.trailing)
		end

primitive PongCommand is ClientCommand
	fun command(): String val => "PONG"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		None

primitive PrivmsgCommand is ClientCommand
	fun command(): String val => "PRIVMSG"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) =>
		try
			let target = msg.params(0)?
			if target.substring(0, 1) == "#" then // TODO make this understand configurable channel prefix characters.
				user.registries.channels.privmsg(user, msg.with_prefix(user.prefix()))
			else
				user.registries.users.privmsg(user, msg.with_prefix(user.prefix()))
			end
		end


primitive UserCommand is ClientCommand
	fun command(): String val => "USER"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateRegistered; _UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		try
			user.user = msg.params(0)?
			user.real = msg.trailing
		end
		user.out.print("user is: " + user.nick)
		user.out.print("real is: " + user.real)
		match user.state()
		| _UserStateCapabilitiesNickKnown =>
			user.change_state(_UserStateCapabilitiesUserKnown)
		| _UserStateNickKnown =>
			user.change_state(_UserStateRegistered)
			user.registries.users.add(user)
			user.send_initial_stats()
		end

primitive CapCommand is ClientCommand
	fun command(): String val => "CAP"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected]) // TODO restrict this some more?
	fun handle(user: User ref, msg: Message) =>
		// TODO LS [302]; LIST; REQ; END; NAK, ACK; NEW; DEL.
		let sub_command = try msg.params(0)? else "LS" end
		match sub_command
		| "LS" =>
			user.change_state(_UserStateCapabilityList)
			// TODO if trailing gets too long; split it into multiple
			//   messages (CAP LS >302 and CAP LS <302)
			// TODO CAP LS post registration
			var trailing: String iso = recover iso String() end
			for c in _Capabilities.all_as_string().values() do
				if trailing.size() != 0 then trailing.append(" ") end
				trailing.append(c)
			end
			user.to_client(Message.create("", "CAP", ["*"; "LS"], consume trailing))
		| "REQ" =>
			// TODO caps can be prefixed with a - to indicate that that cap should be disabled.
			let caps: Array[Capability] = Array[Capability](5) // XXX 5: rough max count of available caps.
			let cap_options: Array[String] = msg.trailing.split(" ")
			for cap_option in cap_options.values() do
				match _Capabilities.from_string(cap_option)
				| let c: Capability => caps.push(c)
				end
			end
			user.enable_capabilities(caps)
			var trailing: String iso = recover iso String() end
			for c in caps.values() do
				if trailing.size() != 0 then trailing.append(" ") end
				trailing.append(c())
			end
			user.to_client(Message.create("", "CAP", ["*"; "ACK"], consume trailing))
		| "END" =>
			if (user.nick != "") and (user.user != "") then
				user.change_state(_UserStateRegistered)
				user.registries.users.add(user)
				user.send_initial_stats()
			else
				user.change_state(_UserStateCapabilitiesNegotiated)
			end
		else
			user.to_client(Message.create("", "410", ["*"; msg.command], "Invalid CAP command"))
		end

primitive NickCommand is ClientCommand
	fun command(): String val => "NICK"
	fun user_states(): Array[_UserState] val => _UserStates.all_but([_UserStateDisconnected])
	fun handle(user: User ref, msg: Message) =>
		let oldfull = user.full
		try user.nick = msg.params(0)?  end
		match user.state()
		| _UserStateConnected => user.change_state(_UserStateNickKnown)
		| _UserStateCapabilityList => user.change_state(_UserStateCapabilitiesNickKnown)
		| _UserStateRegistered =>
//			user.registries.channels.
//			user.registries.users.
			user.to_client(Message(oldfull, "NICK", [], user.nick))
		end

primitive JoinCommand is ClientCommand
	fun command(): String val => "JOIN"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) =>
		user.registries.channels.join(user, msg.with_prefix(user.prefix()))

primitive PartCommand is ClientCommand
	fun command(): String val => "PART"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) =>
		user.registries.channels.part(user, msg.with_prefix(user.prefix()))

primitive TopicCommand is ClientCommand
	fun command(): String val => "TOPIC"
	fun user_states(): Array[_UserState] val => [_UserStateRegistered]
	fun handle(user: User ref, msg: Message) =>
		user.registries.channels.update_topic(user, msg.with_prefix(user.prefix()))

primitive QuitCommand is ClientCommand
	fun command(): String val => "QUIT"
	fun user_states(): Array[_UserState] val => _UserStates.all()
	fun handle(user: User ref, msg: Message) =>
		user.registries.channels.quit(user, msg.with_prefix(user.prefix()))
		user.registries.users.quit(user, msg.with_prefix(user.prefix()))
		user.change_state(_UserStateDisconnected)
		user.connection.dispose()

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
		add_allof(CapCommand)
		add_allof(PrivmsgCommand)
		add_allof(JoinCommand)
		add_allof(PartCommand)
		add_allof(TopicCommand)
		add_allof(QuitCommand)

	fun ref add_allof(cmd: ClientCommand val) =>
		for s in cmd.user_states().values() do
			//@printf[None]("Adding %s / %s\n".cstring(), cmd.command().cstring(), s.apply().cstring())
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
	let capabilities: Set[Capability] = Set[Capability](5) // XXX rough guess.

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

	fun ref enable_capabilities(caps: Array[Capability]) =>
		capabilities.union(caps.values())

	fun ref prefix(): String =>
		nick + "!" + user + "@" + host

	fun ref change_state(to: _UserState) =>
		if _UserStates.allowed(_state, to) then
			out.print("Changing state from " + _state() + " to " + to())
			_state = to
		else
			out.print("Disallowing state change from " + _state() + " to " + to())
		end

	fun ref state(): _UserState =>
		_state

	be to_client_with_nick(msg: Message) =>
		connection.write(msg.with_param_first(nick).string() + "\r\n") // XXX should call `_to_client`
	be to_client(msg: Message) =>
		_to_client(msg)
	fun ref _to_client(msg: Message) =>
		connection.write(msg.string() + "\r\n")

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

