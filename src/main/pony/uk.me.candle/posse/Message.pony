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
	let params: Array[String]
	let a: Array[String]

	fun string(): String =>
		var result = String()
		result.append(prefix)
			.append(" ")
			.append(command)
		for s in params.values() do
			result.append(" ")
			result.append(s)
		end
		result.append(":")
			.append(trailing)
		result.clone()

	new val create(
			raw': String,
			prefix': String,
			command': String,
//			params': Array[String] val,
			trailing': String//,
//			a': Array[String] val = Array[String](0)
			) =>
		raw = raw'
		prefix = prefix'
		command = command'
		trailing = trailing'
		params = Array[String](0)
		a = Array[String](0)
//		params = params'
//		a = a'

	new val from_raw(raw': String) =>
		var prefix' = ""
		var command' = ""
		var trailing' = ""
		var params' = Array[String](0)
		var a' = Array[String](0)
		try
			let re = Regex(_pattern)
			let matched = re(raw')
			a' = matched.groups()
			prefix' = matched.groups().apply(1)
			command' = matched.groups().apply(2)
			params' = matched.groups().apply(3).clone().strip(" ").split(" ")
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
		params = params'







