use "net"
use "collections"
use "format"

actor Main
	new create(env: Env) =>
		let channels = ChannelRegistry.create()
		let users = UserRegistry.create(channels)
		let server = ServerStats.create("posse", "0.1", users, channels)

		try
			let listen = ServerListen.create(env.out, users, server)
			TCPListener.create(
				env.root as AmbientAuth,
				consume listen,
				"localhost",
				"6789"
				)
		else
			env.out.print("Failed to create listener")
		end

primitive IPAddrString
	fun apply(address: IPAddress): String =>
		var addr = ""
		var service = ""
		try (addr, service) = address.name() end
		var result = String.create()
		if address.ip6() then
			result.append("[")
		end
		result.append(addr)
		if address.ip6() then
			result.append("]")
		end
		result.append(":")
		result.append(service)
		result.clone()

primitive ArrString
	fun apply(out: OutStream, data: Array[U8]) =>
		for b in data.values() do
			out.write(Format.int[U8](b, FormatHexSmallBare))
			out.write(" ")
		end
		out.write("\n")

// vi: sw=4 sts=4 ts=4 noet
