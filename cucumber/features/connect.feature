Feature: connecting to the server

Scenario: Correct connection sequence
  When I connect and send these commands on connection 0
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |


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
