use "collections"
use "time"

actor ServerStats
	let server_name: String
	let version: String
	let user_registry: UserRegistry
	let channel_registry: ChannelRegistry
	let start_time: PosixDate

	new create(server_conf': ServerConfig, user_registry': UserRegistry, channel_registry': ChannelRegistry) =>
		server_name = server_conf'.server_name
		version = server_conf'.server_version
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

