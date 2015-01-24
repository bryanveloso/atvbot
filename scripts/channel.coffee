# Description:
#   Functionality around the channel. Like hosting.

# Firebase.
Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

# Firebase keys.
hosts = firebase.child('hosts')
subscribers = firebase.child('subscribers')

module.exports = (robot) ->
  # Listening for incoming host notifications.
  # Because hosting is only reported to the broadcaster's account, this code
  # is required to be run from a bot linked to said account.
  robot.hear /^([a-zA-Z0-9_]*) is now hosting you for (\d*) viewers.$/, (msg) ->
    if msg.envelope.user.name is 'jtv'
      hosts = hosts.push()
      hosts.set
        username: msg.match[1],
        viewers: msg.match[2]
      , (error) ->
        console.log "We've been hosted by #{msg.match[1]}."

  # Listening for incoming subscription notifications. :O
  robot.hear /^([a-zA-Z0-9_]*) just subscribed!$/, (msg) ->
    if msg.envelope.user.name is 'twitchnotify'

      subscribers.child(username).on 'child_added', (snapshot) ->
        unless snapshot.val()?
          timestamp = Firebase.ServerValue.TIMESTAMP
          subscribers = subscribers.push()
          subscribers.setWithPriority
            username: msg.match[1],
            timestamp: timestamp
          , timestamp, (error) ->
            console.log "#{msg.match[1]} has just subscribed!"
