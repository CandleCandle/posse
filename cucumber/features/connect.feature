Feature: connecting to the server

Scenario: Correct connection sequence
  When I connect and send these commands on connection 0
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |

Scenario: Connecting with CAP LS, requesting no capabilities
  When I connect and send these commands on connection 0
    | CAP LS |
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | CAP * LS :server-time |
  When I send these commands on connection 0
    | CAP END |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |

Scenario: Connecting with CAP LS, requesting server-time capabilities
  When I connect and send these commands on connection 0
    | CAP LS |
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | CAP * LS :server-time |
  When I send these commands on connection 0
    | CAP REQ :server-time |
  Then I receive these responses on connection 0
    | CAP * ACK :server-time |
  When I send these commands on connection 0
    | CAP END |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |

Scenario: messages sent by a non-server-time client are received with a timestamp
  When I connect and send these commands on connection 0
    | CAP LS |
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | CAP * LS :server-time |
  When I send these commands on connection 0
    | CAP REQ :server-time |
  Then I receive these responses on connection 0
    | CAP * ACK :server-time |
  When I send these commands on connection 0
    | CAP END |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |
  When I send these commands on connection 0
    | JOIN #watch |
  When I connect and send these commands on connection 1
    | NICK cucumber1 |
    | USER carrot1 * * :aubergine1 |
    | JOIN #watch |
    | PRIVMSG #watch :fire! |
  Then I receive matching responses on connection 0
    | @time=\d{4}-\d{2}\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z\|([+-][0-9:]{2,5})) :cucumber1!carrot1@[^ ]+ PRIVMSG #watch :fire! |


Scenario: quitting the server happily
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  When I connect and send these commands on connection 1
    | NICK cucumber1 |
    | USER carrot1 * * :aubergine1 |
    | JOIN #watch |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber0 |
  When I send these commands on connection 0
    | QUIT :some quit message |
  Then I receive matching responses on connection 1
    | :cucumber0!carrot0@([^ ]+) QUIT :some quit message |
  And the socket for connection 1 is closed

# TODO more abrupt quitting - i.e. client closed the connection; client timed out.

# vi: sw=2 ts=2 sts=2 et
