use "net"
use "buffered"

class ClientHandler is TCPConnectionNotify
	let out: OutStream
	let listen: TCPListener
	let users: UserRegistry
	let server: ServerStats
	var user: (User | None) = None

	new iso create(out': OutStream, listen': TCPListener, users': UserRegistry, server': ServerStats) =>
		out = out'
		listen = listen'
		users = users'
		server = server'

	fun ref accepted(conn: TCPConnection ref) =>
		out.print("* accepted")
		user = User.create(out, conn, conn.remote_address(), users, server)

	fun closed(conn: TCPConnection ref) =>
		out.print("* closed / TCPConnectionNotify")

	fun connecting(conn: TCPConnection ref, count: U32 val) =>
		out.print("* connecting / " + count.string())
		// not used as it's an inbound connection.

	fun ref connected(conn: TCPConnection ref) =>
		out.print("* connected / TCPConnectionNotify")
		// not used as it's an inbound connection.

	fun connect_failed(conn: TCPConnection ref) =>
		out.print("* connect failed")
		// not used as it's an inbound connection.

	fun sent(conn: TCPConnection ref, data: (String val | Array[U8 val] val))
		: (String val | Array[U8 val] val) =>
//		out.write("<** ")
//		let output: String = match data
//				| let s: String => ArrString(out, s.array().clone()); s.clone().>strip().clone()
//				| let a: Array[U8] val => ArrString(out, a.clone()); String.from_array(a).clone().>strip().clone()
//			end
		match data
		| let s: String => out.print("<<< " + IPAddrString(conn.remote_address()) + " <<< " + s)
		| let a: Array[U8] val => out.print("<<< " + IPAddrString(conn.remote_address()) + " <<< " + "<binary>")
		end
		data

	fun fin(conn: TCPConnection ref) =>
		listen.dispose()
		conn.dispose()

	fun ref received(conn: TCPConnection ref, data: Array[U8 val] iso, times: USize): Bool =>
		let reader = Reader
		reader.append(consume data)
		while true do
			try
				var input = reader.line()
//				out.write(">** ")
//				ArrString(out, input.array().clone())
				out.print(">>> " + IPAddrString(conn.remote_address()) + " >>> " + input.clone())

				match user
				| let u: User => u.from_client(Message.from_raw(consume input))
				end
			else
				// XXX work out what to do when there are bytes remaining.
				break
			end
		end
		true

// vi: sw=4 sts=4 ts=4 noet
