use "net"


class ServerListen is TCPListenNotify
	let out: OutStream
	let registries: Registries
	let server: ServerStats

	new iso create(out': OutStream, registries': Registries, server': ServerStats) =>
		out = out'
		registries = registries'
		server = server'

	fun listening(listen: TCPListener ref) =>
		var addr = ""
		var service = ""
		try (addr, service) = listen.local_address().name()? end
		out.print("* listening on: " + IPAddrString(listen.local_address()))

	fun ref not_listening( listen: TCPListener ref) =>
		out.print("Failed to listen on " + IPAddrString(listen.local_address()))

	fun closed(listen: TCPListener ref) =>
		out.print("* closed / TCPListenNotify")

	fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
		out.print("* connected / TCPListenNotify")
		ClientHandler.create(out, listen, registries, server)

// vi: sw=4 sts=4 ts=4 noet
