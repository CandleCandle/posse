use "regex"
use "collections"

class val Message
	let _pattern: String =
			"^"
			+ "(@(?<tags>[^ ]*) )?"
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
	let tags: Map[String, (None | String)] val
	let a: Array[String]

	fun string(): String =>
		var result = String()
		if tags.size() > 0 then
			result.>append("@")
			for (k, v) in tags.pairs() do
				if result.size() > 1 then result.append(";") end
				result.append(k)
				match v
				| let vs: String => result.>append("=").>append(vs)
				end
			end
			result.>append(" ")
		end

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
		tags = recover val Map[String, (None | String)](0) end
		a = Array[String](0)

	new val from_raw(raw': String) =>
		var prefix' = ""
		var command' = ""
		var trailing' = ""
		var params' = recover iso Array[String](0) end
		var tags': Map[String, (None | String)] iso = recover iso Map[String, (None | String)](0) end
		var a' = Array[String](0)
		try
			let re = Regex(_pattern)?
			let matched = re(raw')?
			a' = matched.groups()
			tags' = parse_tags(matched.groups().apply(1)?)?
			prefix' = matched.groups().apply(3)?
			command' = matched.groups().apply(4)?
			params'.append(matched.groups().apply(5)?.clone().>strip(" ").split(" "))
			trailing' = matched.groups().apply(8)?
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
		tags = consume tags'

	fun val with_prefix(prefix': String): Message =>
		Message(prefix', command, params, trailing)

	fun tag parse_tags(tags_str: String): Map[String, (None | String)] iso^ ? =>
		@printf[None]("tags: str: %s\n".cstring(), tags_str.cstring())
		// rough guess at tag count
		let count: USize = tags_str.count(";")
		@printf[None]("tags: count: %d\n".cstring(), count)
		let result = recover iso Map[String, (None | String)](count) end
		for bit in tags_str.split(";").values() do
			@printf[None]("tags: bit: %s\n".cstring(), bit.cstring())
			if bit.contains("=") then
				let kv = bit.split("=", 2)
				@printf[None]("tags: kv: %s => %s\n".cstring(), kv(0)?.cstring(), kv(1)?.cstring())
				result.update(kv(0)?, kv(1)?)
			else
				@printf[None]("tags: k: %s\n".cstring(), bit.cstring())
				result.update(bit, None)
			end
		end
		consume result

	fun val with_param_first(param': String): Message =>
		let params': Array[String val] iso = recover iso Array[String val] end
		params'.push(param')
		params'.append(params)
		Message(prefix, command, consume params', trailing)

	fun val with_param(param': String): Message =>
		let params': Array[String val] iso = recover iso params.clone() end
		params'.push(param')
		Message(prefix, command, consume params', trailing)

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








