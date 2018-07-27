use "regex"

class val Message
	let _pattern: String =
			"^"
			+ "(:(?<prefix>[-.a-zA-Z0-9!@]+) )?"
//			+ "(?<command>.)"
//			+ "(?<params>.)"
//			+ "(?<trailing>.*)"
			+ "(?<command>[^ ]+)"
			+ "( (?<params>[^:]*))?"
			+ "( :(?<trailing>.*))?"
//			+ "(?<command>[a-zA-Z]+|[0-9]{3})"
//			+ "( (?<params>([^ :]+ ?)+))?"
//			+ "( :(?<trailing>.*))?"
			+ "$"
	let raw: String
	let prefix: String
	let command: String
	let trailing: String
	let params: Array[String] val
	let a: Array[String]

	fun string(): String =>
		var result = String()
		if (prefix != "") then
			result
				.>append(":")
				.>append(prefix)
				.>append(" ")
		end
		result.append(command)
		for (i, s) in params.pairs() do
			if (i == (params.size()-1)) and (s == trailing) then continue end
			result.append(" ")
			result.append(s)
		end
		if (trailing != "") then
			result.>append(" :")
				.>append(trailing)
		end
		result.clone()

	new val create(
			prefix': String,
			command': String,
			params': Array[String] val,
			trailing': String
			) =>
		raw = ""
		prefix = prefix'
		command = command'
		trailing = trailing'
		params = params'
		a = Array[String](0)

	new val from_raw(raw': String) =>
		var prefix' = ""
		var command' = ""
		var trailing' = ""
		var params' = recover iso Array[String](0) end
		var a' = Array[String](0)
		try
			let re = Regex(_pattern)
			let matched = re(raw')
			a' = matched.groups()
			prefix' = matched.groups().apply(1)
			command' = matched.groups().apply(2)
			params'.append(matched.groups().apply(3).clone().>strip(" ").split(" "))
			trailing' = matched.groups().apply(6)
		end
		a = a'
		raw = raw'
		prefix = prefix'
		command = command'
		trailing = trailing'
		if trailing' != "" then
			params'.push(trailing)
		end
		params = consume params'

	fun prepend_param(param: String): Message val =>
		let params': Array[String val] iso = recover iso Array[String](0) end
		params'.append(params)
		params'.push(param)

		Message.create(
			prefix,
			command,
			consume params',
			trailing
		)








