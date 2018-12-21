use "net"
use "collections"
use "format"
use "options"

actor Main
	new create(env: Env) =>
		try
			let server_conf = ServerConfig.from_args(env.args, env.out)?
			let channels = ChannelRegistry.create(server_conf)
			let users = UserRegistry.create()
			let registries = Registries(channels, users)

			let server = ServerStats.create(server_conf, users, channels)
			let listen = ServerListen.create(env.out, registries, server)
			TCPListener.create(
				env.root as AmbientAuth,
				consume listen,
				server_conf.host,
				server_conf.service
				)
		else
			env.out.print("Failed to create listener")
		end

class val ServerConfig
	let host: String
	let service: String
	let server_name: String
	let server_version: String

	new val from_args(args: Array[String val] val, out: OutStream) ? =>
		var options = Options(args)
		options
			.add("host", "h", StringArgument)
			.add("port", "p", StringArgument)
			.add("name", "n", StringArgument)
		
		var host': String iso = (recover String end).>append("localhost")
		var service': String iso = (recover String end).>append("6667")
		var server_name': String iso = (recover String end).>append("posse")

		for option in options do
			match option
			| ("host", let arg: String) => host'.>clear().append(arg)
			| ("port", let arg: String) => service'.>clear().append(arg)
			| ("name", let arg: String) => server_name'.>clear().append(arg)
			| let err: ParseError => err.report(out) ; error
			end
		end

		host = consume host'
		service = consume service'
		server_name = consume server_name'
		server_version = "0.1"

class val Registries
	let channels: ChannelRegistry
	let users: UserRegistry

	new val create(channels': ChannelRegistry, users': UserRegistry) =>
		channels = channels'
		users = users'

primitive IPAddrString
	fun apply(address: NetAddress, port: Bool = true): String =>
		var addr = ""
		var service = ""
		try (addr, service) = address.name()? end
		var result = String.create()
		if address.ip6() then
			result.append("[")
		end
		result.append(addr)
		if address.ip6() then
			result.append("]")
		end
		if port then
			result.append(":")
			result.append(service)
		end
		result.clone()

primitive ArrString
	fun apply(out: OutStream, data: Array[U8]) =>
		for b in data.values() do
			out.write(Format.int[U8](b, FormatHexSmallBare))
			out.write(" ")
		end
		out.write("\n")

// vi: sw=4 sts=4 ts=4 noet
