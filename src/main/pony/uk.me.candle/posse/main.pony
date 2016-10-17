use "net"

actor Main
	new create(env: Env) =>
		let channels = ChannelRegistry.create()
		let users = UserRegistry.create(channels)

		try
			let listen = ServerListen.create(env.out, users)
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

// vi: sw=4 sts=4 ts=4 noet
