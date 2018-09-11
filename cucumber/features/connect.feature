Feature: connecting to the server

Scenario: Correct connection sequence
  When I connect and send these commands on connection 0
    | NICK cucumber |
    | USER carrot * * :aubergine |
  Then I receive these responses on connection 0
    | :server_name 001 cucumber |

#Scenario: Channels
#  When I connect and send these commands on connection 0
#    | NICK cucumber0 |
#    | USER carrot * * :aubergine1 |
#  When I connect and send these commands on connection 1
#    | NICK cucumber1 |
#    | USER carrot1 * * :aubergine1 |
#  Then I receive these responses on connection 0
#    | :server_name 001 cucumber |
#  Then I receive these responses on connection 1
#    | :server_name 001 cucumber |
#  When I send these commands on connection 0


# vi: sw=2 ts=2 sts=2 et
