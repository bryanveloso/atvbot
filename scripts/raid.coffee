# Description:
#   Functionality around raids.
#
# Commands:
#   hubot raider <username> - Searches Twitch for <username> and returns a follow message plus last game played.

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
        robot.http('http://avalonstar.tv/live/status/').get() (err, res, body) ->
          status = JSON.parse(body)

          # Let's record this raid to the Avalonstar API.
          json =
            'broadcast': status.episode
            'game': streamer.game
            'raider': streamer.name
            'timestamp': new Date(Date.now()).toISOString()
          robot.http('http://avalonstar.tv/api/raids/')
            .post(json) (err, res, body) ->
              if err
                robot.logger.error "The raid by #{query} couldn't be recorded."
                return
              robot.logger.info "The raid by #{query} was recorded."

      # Let's get outta here.
      return

  robot.respond /testraid/i, (msg) ->
    # Testing raids.
    # Get the status of the Episode from the API.
    json =
      'broadcast': 115
      'game': 'StepMania'
      'raider': 'avalonstar'
      'timestamp': new Date(Date.now()).toISOString()
    robot.http('http://avalonstar.tv/api/raids/').post(json) (err, res, body) ->
      if err
        robot.logger.error "The raid couldn't be recorded."
        return
      robot.logger.info "The raid was recorded."
