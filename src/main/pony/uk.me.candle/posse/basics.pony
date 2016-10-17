use "net"


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
	var nick: String
	var user: String
	var real: String
	var host: String

	new create(out': OutStream, connection': TCPConnection, users': UserRegistry) =>
		out = out'
		connection = connection'
		users = users'
		nick = ""
		real = ""
		host = ""
		user = ""

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
		end

	be to_client(msg: Message) =>
		connection.write(msg.string())

	be do_nick(msg: Message) =>
		//TODO if check_nick() then
		try
			nick = msg.params(0)
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
			user = msg.params(0)
			real = msg.trailing
		// else TODO respond with error.
		end
		check_logged_in_correctly_and_send_initial_stuff()

	be check_logged_in_correctly_and_send_initial_stuff() =>
		// TODO rename.
		if (nick != "") and (real != "") then
			to_client(Message.from_raw("CONNECTED")) // TODO lookup these messages
		end


