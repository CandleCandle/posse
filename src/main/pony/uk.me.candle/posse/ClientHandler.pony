use "net"
use "buffered"

class ClientHandler is TCPConnectionNotify
	let out: OutStream
	let listen: TCPListener
	let users: UserRegistry
	var user: (User | None) = None

	new iso create(out': OutStream, listen': TCPListener, users': UserRegistry) =>
		out = out'
		listen = listen'
		users = users'

	fun ref accepted(conn: TCPConnection ref) =>
		out.print("* accepted")
		user = User.create(out, conn, users)

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
		var output: String = match data
				| let s: String => s
				| let a: Array[U8] val => String.from_array(a)
			else
				""
			end
		out.write("<<< " + IPAddrString(conn.remote_address()) + " <<< " + output)
		data

	fun fin(conn: TCPConnection ref) =>
		listen.dispose()
		conn.dispose()

	fun received(conn: TCPConnection ref, data: Array[U8 val] iso) =>
		var input = String.from_array(consume data)
		out.write(">>> " + IPAddrString(conn.remote_address()) + " >>> " + input)

		match user
		| let u: User => u.from_client(Message.from_raw(input.clone().strip().clone()))
		end

// vi: sw=4 sts=4 ts=4 noet
