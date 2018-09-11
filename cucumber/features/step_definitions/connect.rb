

When("I connect and send these commands") do |table|
  @client = IrcClient.new(IRCD.host, IRCD.port).start

  table.raw.each do |row|
    @client.send(row[0] + "\015\012")
  end
end

Then("I receive these responses") do |table|
  sleep 1
  lines = @client.responses.to_a.map {|l| l.strip}

  table.raw.each do |row|
    expect(lines).to include(row[0].strip)
  end
end


# vi: sw=2 ts=2 sts=2 et
