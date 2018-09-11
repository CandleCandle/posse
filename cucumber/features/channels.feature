Feature: joining and leaving channels

Scenario: Joining Channels
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  Then I receive matching responses on connection 0
    | :cucumber0!carrot0@\[::1\] JOIN #watch |
    | 353 cucumber0 = #watch :cucumber0 |
    | 366 cucumber0 #watch :End of /NAMES |


# all with 2 connections:
# see second person join channel
# change topic, see change on both

# channel modes
# private, invite only channels?
#

# privmsg - should be in a separate feature file?

# vi: sw=2 ts=2 sts=2 et

