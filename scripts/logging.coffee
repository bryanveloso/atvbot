# Description:
#   Functionality around logging to the Avalonstar(tv) API.

Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

module.exports = (robot) ->
  handleUser = (username) ->
  #   # First, we need to fill the robot's brain with a viewer object.
  #   if robot.brain.data.viewers[username]?
  #     robot.brain.data.viewers[username] =
  #       'name': username
  #     robot.brain.save()
  #     robot.logger.debug "#{username} has been added to the brain."

  #   # Check if we have a user on Firebase. If not, create it.
  #   viewers = firebase.child('viewers')
  #   viewers.child(username).once 'value', (snapshot) ->
  #     unless snapshot.val()?
  #       robot.http("https://api.twitch.tv/kraken/users/#{username}")
  #         .get() (err, res, body) ->
  #           viewer = JSON.parse(body)

  #           # Let's record things.
  #           json =
  #             'display_name': viewer.display_name
  #             'username': username
  #           viewers.child(username).set json, (error) ->
  #             robot.logger.debug "#{username} has been added to Firebase." if error?

  robot.enter (msg) ->
    robot.adapter.command 'CAP', 'REQ', ':twitch.tv/tags'

  #   # Reset Hubot's autosave interval to 30s instead of 5.
  #   # This is to prevent unnecessary reloading of old data. :(
  #   robot.brain.resetSaveInterval 30

  # # Listen to joins (which only happen on `TWITCHCLIENT 1`.), create a user
  # # if they don't exist in the database!
  # robot.adapter.bot.addListener 'join', (channel, username, message) ->
  #   handleUser username unless username is 'jtv'

  # # As a backup, listen to messages. Create a user if they don't exist in
  # # the database!
  # robot.adapter.bot.addListener 'message', (from, to, message) ->
  #   handleUser from unless from is 'jtv'
