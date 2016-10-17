use "net"


class ServerListen is TCPListenNotify
	let out: OutStream
	var users: UserRegistry

	new iso create(out': OutStream, users': UserRegistry) =>
		out = out'
		users = users'

	fun listening(listen: TCPListener ref) =>
		var addr = ""
		var service = ""
		try (addr, service) = listen.local_address().name() end
		out.print("* listening on: " + IPAddrString(listen.local_address()))

	fun not_listening( listen: TCPListener ref) =>
		out.print("Failed to listen on " + IPAddrString(listen.local_address()))

	fun closed(listen: TCPListener ref) =>
		out.print("* closed / TCPListenNotify")

	fun connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
		out.print("* connected / TCPListenNotify")
		let handler = ClientHandler.create(out, listen, users)
		handler

// vi: sw=4 sts=4 ts=4 noet