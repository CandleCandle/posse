Feature: joining and leaving channels

Scenario: Joining Channels
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  Then I receive matching responses on connection 0
    | :cucumber0!carrot0@((\[::1\])\|(127\.0\.\d+\.\d+)) JOIN #watch |
    | ^:server_name 331 #watch |
    | 353 cucumber0 = #watch :cucumber0 |
    | 366 cucumber0 #watch :End of /NAMES |


Scenario: Joining Channels as observed by others
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  When I connect and send these commands on connection 1
    | NICK cucumber1 |
    | USER carrot1 * * :aubergine1 |
    | JOIN #watch |
  Then I receive matching responses on connection 0
    | :cucumber1!carrot1@([^ ]+) JOIN #watch |
  Then I receive matching responses on connection 1
    | :cucumber1!carrot1@([^ ]+) JOIN #watch |
    | 353 cucumber1 = #watch :cucumber0 |
    | 353 cucumber1 = #watch :cucumber1 |
    | 366 cucumber1 #watch :End of /NAMES |

Scenario: Topic changes are observed by members of the channel
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
    | TOPIC #watch :this is a new topic |
  Then I receive matching responses on connection 0
    | 332 #watch :this is a new topic |
  Then I receive matching responses on connection 1
    | 332 #watch :this is a new topic |
  And I have not received these matching responses on connection 2
    | 332 #watch :this is a new topic |

Scenario: Topic changes are observed by new members of the channel
  When I connect and send these commands on connection 0
    | NICK cucumber0 |
    | USER carrot0 * * :aubergine0 |
    | JOIN #watch |
  When I send these commands on connection 0
    | TOPIC #watch :topic should be observed on join |
  When I connect and send these commands on connection 1
    | NICK cucumber1 |
    | USER carrot1 * * :aubergine1 |
    | JOIN #watch |
  Then I receive matching responses on connection 1
    | 332 #watch :topic should be observed on join |

# all with 2 connections:
# change topic, see change on both

# channel modes
# private, invite only channels?
#

# privmsg - should be in a separate feature file?

# vi: sw=2 ts=2 sts=2 et

