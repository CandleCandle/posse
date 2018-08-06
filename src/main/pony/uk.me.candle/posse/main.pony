use "net"
use "collections"
use "format"

actor Main
	new create(env: Env) =>
		let channels = ChannelRegistry.create()
		let users = UserRegistry.create()
		let server = ServerStats.create("posse", "0.1", users, channels)
		let registries = Registries(channels, users)

		try
			let listen = ServerListen.create(env.out, registries, server)
			TCPListener.create(
				env.root as AmbientAuth,
				consume listen,
				"localhost",
				"6789"
				)
		else
			env.out.print("Failed to create listener")
		end

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
