Feature: connecting to the server

Scenario: Correct connection sequence
  When I connect and send these commands
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses
    | :server_name 001 cucumber |


# vi: sw=2 ts=2 sts=2 et
