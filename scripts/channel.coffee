# Description:
#   Functionality around the channel. Like hosting.

module.exports = (robot) ->
  # Listening for incoming host notifications.
  # Because hosting is only reported to the broadcaster's account, this code
  # is required to be run from a bot linked to said account.
  robot.hear /([a-zA-Z0-9_]*) is now hosting you for (\d*) viewers./, (msg) ->
    robot.logger.info "We've been hosted by #{msg.match[1]}."
