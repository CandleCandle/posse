use "collections"
use "itertools"
use "promises"

actor ChannelRegistry
	let server_conf: ServerConfig
	var channels: Map[String, Channel] = Map[String, Channel]

	new create(server_conf': ServerConfig) =>
		server_conf = server_conf'

	be join(user: User, msg: Message) =>
		try
			let channel_name = msg.params(0)?
			if not channels.contains(channel_name) then
				channels(channel_name) = Channel(server_conf, channel_name)
			end
			channels(channel_name)?.join(user, msg)
		else
			user.to_client(Message("", "461", [], "Not enough parameters"))
		end

	be part(user: User, msg: Message) =>
		try
			let channel_name = msg.params(0)?
			channels(channel_name)?.part(user, msg)
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

	be privmsg(user: User, msg: Message) =>
		try
			let channel_name = msg.params(0)?
			if channels.contains(channel_name) then
				channels(channel_name)?.privmsg(user, msg)
			else
				user.to_client(Message("", "403", [channel_name], "no such channel"))
			end
		// else // TODO handle malformed channel names.
		end

	be quit(user: User, msg: Message) =>
		for c in channels.values() do
			c.quit(user, msg)
		end

actor Channel
	let server_conf: ServerConfig
	let users: Array[User] = Array[User].create()
	let name: String
	var topic: String = ""

	new create(server_conf': ServerConfig, name': String) =>
		server_conf = server_conf'
		name = name'

	be join(user: User, msg: Message) =>
		// before "joining": RPL_TOPIC
		if topic.size() > 0 then
			user.to_client(Message(server_conf.server_name, "332", [name], topic.clone())) // RPL_TOPIC
		else
			user.to_client(Message(server_conf.server_name, "331", [name], "")) // RPL_NOTOPIC
		end

		users.push(user)
		// after "joining": RPL_NAMREPLY so that this user is included in the reply.

		// should join names to reduce the number of messages sent.

		let ps: Iterator[Promise[String]] = Iter[User](users.values())
			.map[Promise[String]]({(u: User): Promise[String] =>
				let p = Promise[String]
				u.with_nick(p)
				p
			})
		Promises[String val].join(ps)
			.next[None]({(nicks: Array[String val] val) =>
				for n in nicks.values() do
					user.to_client_with_nick(Message("", "353", ["="; name], n)) // RPL_NAMREPLY
				end
				user.to_client_with_nick(Message("", "366", [name], "End of /NAMES")) // RPL_ENDOFNAMES
			})

		send_to_all_users(msg)

	be quit(user: User, msg: Message) =>
		// XXX If two users share channels, then the non-quitting user will get multiple QUIT messages.
		if users.contains(user) then
			try users.delete(users.find(user)?)? end
			send_to_all_other_users(user, msg)
		end

	be part(user: User, msg: Message) =>
		try users.delete(users.find(user)?)? end
		send_to_all_other_users(user, msg)

	be update_topic(user: User, msg: Message) =>
		topic = msg.trailing
		for u in users.values() do
			u.to_client(Message("", "332", [name], topic.clone()))
		end

	be privmsg(user: User, msg: Message) =>
		// TODO check channel modes.
		send_to_all_other_users(user, msg)

	fun ref send_to_all_users(msg: Message) =>
		for u in users.values() do
			u.to_client(msg)
		end

	fun ref send_to_all_other_users(user: User, msg: Message) =>
		for u in users.values() do
			if not (u is user) then
				u.to_client(msg)
			end
		end

