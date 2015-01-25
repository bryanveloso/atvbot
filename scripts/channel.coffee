# Description:
#   Functionality around the channel. Like hosting.

# Firebase.
Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

# Pusher.
Pusher = require 'pusher'
pusher = new Pusher
  appId: process.env.PUSHER_APP_ID
  key: process.env.PUSHER_KEY
  secret: process.env.PUSHER_SECRET

# Firebase keys.
hosts = firebase.child('hosts')
subscribers = firebase.child('subscribers')

module.exports = (robot) ->
  # Listening for incoming host notifications.
  # Because hosting is only reported to the broadcaster's account, this code
  # is required to be run from a bot linked to said account.
  robot.hear /^([a-zA-Z0-9_]*) is now hosting you for (\d*) viewers.$/, (msg) ->
    if msg.envelope.user.name is 'jtv'
      # First, push the data to Pusher to power the notification.
      username = msg.match[1]
      if msg.match[2] > 0
        pusher.trigger 'live', 'hosted',
          username: username

      # Push the data to Firebase for safe keeping.
      hosts = hosts.push()
      hosts.set
        username: username
        viewers: msg.match[2]
      , (error) ->
        console.log "We've been hosted by #{username}."

  # Listening for incoming subscription notifications. :O
  robot.hear /^([a-zA-Z0-9_]*) just subscribed!$/, (msg) ->
    if msg.envelope.user.name is 'twitchnotify'
      # Take the name and push it on through.
      username = msg.match[1]
      pusher.trigger 'live', 'subscribed',
        username: username
      robot.logger.debug "#{username} has just subscribed!"

  # Listening for incoming re-subscription notifications.
  # This time we capture the number of months they've been subscribed.
  robot.hear /^([a-zA-Z0-9_]*) just subscribed! (\d{1,2}) months in a row!$/, (msg) ->
    if msg.envelope.user.name is 'twitchnotify'
      # Take the name and push it on through.
      username = msg.match[1]
      pusher.trigger 'live', 'subscribed',
        username: username
        length: msg.match[2]
      robot.logger.debug "#{username} has just subscribed!"

  # Backup command for calling subscribers.
  # Strictly for testing and in case anything goes wrong with TwitchNotify.
  robot.respond /s ([a-zA-Z0-9_]*)/, (msg) ->
    if msg.envelope.user.name is 'avalonstar'
      username = msg.match[1] or 'Test'
      pusher.trigger 'live', 'subscribed',
        username: username
