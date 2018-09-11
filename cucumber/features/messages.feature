Feature: Messages are sent and received


Scenario: Channel messages are only observed by members of the channel
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  When I connect and send these commands on connection 1
    | NICK cucumber1 |
    | USER carrot1 * * :aubergine1 |
    | JOIN #watch |
  When I connect and send these commands on connection 2
    | NICK cucumber2 |
    | USER carrot2 * * :aubergine2 |
  When I send these commands on connection 0
    | PRIVMSG #watch :fire! |
  Then I receive matching responses on connection 1
    | :cucumber0!carrot0@[^ ]+ PRIVMSG #watch :fire! |
  And I have not received these matching responses on connection 0
    | :cucumber0!carrot0@[^ ]+ PRIVMSG #watch :fire! |
  And I have not received these matching responses on connection 2
    | :cucumber0!carrot0@[^ ]+ PRIVMSG #watch :fire! |
