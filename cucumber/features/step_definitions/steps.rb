

When("I connect and send these commands on connection {int}") do |con, table|
  @clients ||= []
  @clients[con] = IrcClient.new(IRCD.host, IRCD.port).start

  table.raw.each do |row|
    @clients[con].send(row[0] + "\015\012")
  end
  sleep 1
end

When("I send these commands on connection {int}") do |con, table|
  table.raw.each do |row|
    @clients[con].send(row[0] + "\015\012")
  end
  sleep 1
end

Then("I receive matching responses on connection {int}") do |con, table|
  lines = @clients[con].responses.to_a.map {|l| l.strip}

  table.raw.each do |row|
    expect(lines.any? {|l| /#{row[0]}/ =~ l }).to eq(true), "did not match /#{row[0]}/"
  end
  sleep 1
end

Then("I have not received these matching responses on connection {int}") do |con, table|
  lines = @clients[con].responses.to_a.map {|l| l.strip}

  table.raw.each do |row|
    expect(lines.any? {|l| /#{row[0]}/ =~ l }).to eq(false), "inadvertantly received a response matching: /#{row[0]}/"
  end
  sleep 1
end

Then("I receive these responses on connection {int}") do |con, table|
  lines = @clients[con].responses.to_a.map {|l| l.strip}

  table.raw.each do |row|
    expect(lines).to include(row[0].strip)
  end
  sleep 1
end

Then("the socket for connection {int} is closed") do |con|
  #### 
end

# vi: sw=2 ts=2 sts=2 et
