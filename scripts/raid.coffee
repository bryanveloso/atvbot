# Description:
#   Functionality around raids.
#
# Commands:
#   hubot raider <username> - Searches Twitch for <username> and returns a follow message plus last game played.

get_status = ->
  robot.http('http://avalonstar.tv/live/status/').get() (err, res, body) ->
    return JSON.parse(body)

module.exports = (robot) ->
  robot.respond /raider ([a-zA-Z0-9_]*)/i, (msg) ->
    # This is the backend portion of the !raider command in Elsydeon. However,
    # unlike Elsy it will respond silently.
    if robot.auth.hasRole(msg.envelope.user, ['admin', 'moderator'])
      query = msg.match[1]
      robot.http("https://api.twitch.tv/kraken/channels/#{query}").get() (err, res, body) ->
        streamer = JSON.parse(body)

        if streamer.status is 404
          robot.logger.debug "#{query} doesn't exist."
          return

        # Get the status of the Episode from the API.
        status = get_status()

        # Let's record this raid to the Avalonstar API.
        # First compose the JSON needed to send it over.
        json =
          'broadcast': status.episode
          'game': streamer.game
          'raider': streamer.name
          'timestamp': new Date(Date.now()).toISOString()

  robot.respond /status/i, (msg) ->
    status = get_status()
    msg.send get_status()
    msg.send status.episode
