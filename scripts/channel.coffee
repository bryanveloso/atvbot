# Description:
#   Functionality around the channel. Like hosting.

# Pusher.
Pusher = require 'pusher'
pusher = new Pusher
  appId: process.env.PUSHER_APP_ID
  key: process.env.PUSHER_KEY
  secret: process.env.PUSHER_SECRET

module.exports = (robot) ->
  # Subscriber functions.
  activateSubscriber = (username, callback) ->
    # Take the name and push it on through.
    puser.trigger 'live', 'resubscribed',
      username: username
    robot.logger.info "#{username} has just re-subscribed!"

    # Update the ticket using the API.
    json = JSON.stringify
      'is_active': true
    robot.http("http://avalonstar.tv/api/tickets/#{username}")
      .header('Content-Type', 'application/json')
      .put(json) (err, res, body) ->
        # Success message.
        ticket = JSON.parse(body)
        statusCode = res.statusCode
        callback ticket, statusCode

  addSubscriber = (username, callback) ->
    # Take the name and push it on through.
    pusher.trigger 'live', 'subscribed',
      username: username
    robot.logger.info "#{username} has just subscribed!"

    # Create the ticket using the API.
    json = JSON.stringify
      'name': username
      'is_active': true
    robot.http('http://avalonstar.tv/api/tickets/')
      .header('Content-Type', 'application/json')
      .post(json) (err, res, body) ->
        # Success message.
        ticket = JSON.parse(body)
        statusCode = res.statusCode
        callback ticket, statusCode

  # Listening for incoming host notifications.
  # Because hosting is only reported to the broadcaster's account, this code
  # is required to be run from a bot linked to said account.
  robot.hear /([a-zA-Z0-9_]*) is now hosting you for (\d*) viewers./, (msg) ->
    if msg.envelope.user.name is 'jtv'
      # First, push the data to Pusher to power the notification.
      username = msg.match[1]
      pusher.trigger 'live', 'hosted',
        username: username
      robot.logger.info "We've been hosted by #{username}."

  # Listening for incoming subscription notifications. :O
  robot.hear /^([a-zA-Z0-9_]*) just subscribed!$/, (msg) ->
    if msg.envelope.user.name is 'twitchnotify'
      username = msg.match[1]
      robot.http("http://avalonstar.tv/api/tickets/#{username}/").get() (err, res, body) ->
        # This is a re-subscription.
        # The user has been found in the API; they've been a subscriber.
        if res.statusCode is 200
          activateSubscriber username, (ticket, status) ->
            robot.logger.info "#{username}'s ticket reactivated successfully." if status is 200
          return
        # This is a new subscription.
        # The user hasn't been found in the API, so let's create it.
        else if res.statusCode is 404
          addSubscriber username, (ticket, status) ->
            robot.logger.info "#{username}'s ticket added successfully." if status is 200
          return

  # Listening for incoming re-subscription notifications.
  # This time we capture the number of months they've been subscribed.
  robot.hear /^([a-zA-Z0-9_]*) subscribed for (\d{1,2}) months in a row!$/, (msg) ->
    if msg.envelope.user.name is 'twitchnotify'
      # Take the name and push it on through.
      username = msg.match[1]
      pusher.trigger 'live', 'substreaked',
        username: username
        length: msg.match[2]
      robot.logger.info "#{username} has been subscribed for #{msg.match[2]} months!"

  # Backup command for calling subscribers.
  # Strictly for testing and in case anything goes wrong with TwitchNotify.
  robot.respond /s ([a-zA-Z0-9_]*)/, (msg) ->
    if msg.envelope.user.name is 'avalonstar'
      username = msg.match[1] or 'Test'
      pusher.trigger 'live', 'subscribed',
        username: username

  robot.respond /ts ([a-zA-Z0-9_]*)/, (msg) ->
    if msg.envelope.user.name is 'avalonstar'
      username = msg.match[1] or 'Test'
      robot.http("http://avalonstar.tv/api/tickets/#{username}/").get() (err, res, body) ->
        if res.statusCode is 200
          msg.send "#{username} is a subscriber."
        else
          msg.send "#{username} isn't subscribed."

  # Backup command for calling donations.
  # Strictly for testing.
  robot.respond /d ([a-zA-Z0-9_]*)/, (msg) ->
    if msg.envelope.user.name is 'avalonstar'
      username = msg.match[1]
      data =
        nickname: username
        amount: 0
        message: 'Sup?'
      robot.http('https://imraising.tv/api/v1/listen?apikey=nuZOkYmLF37yQJdzNLWLRA')
        .post(data) (err, res, body) ->
          robot.logger.info "Mock donation for #{username} complete."
