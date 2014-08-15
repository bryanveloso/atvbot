# Description:
#   Functionality around logging to the Avalonstar(tv) API.

Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

module.exports = (robot) ->
  handleUser = (username) ->
    # Check if we have a user on Firebase. If not, create it.
    viewers = firebase.child('viewers')
    viewers.child(username).once 'value', (snapshot) ->
      unless snapshot.val()?
        json =
          'username': username
        viewers.child(username).set json, (error) ->
          robot.logger.debug "We have new blood: #{username}." if !error?

  robot.enter (msg) ->
    # Use TWITCHCLIENT 1.
    robot.adapter.command 'twitchclient', '1'

    # Reset Hubot's autosave interval to 30s instead of 5.
    # This is to prevent unnecessary reloading of old data. :(
    robot.brain.resetSaveInterval 30

  # Listen to joins (which only happen on `TWITCHCLIENT 1`.), create a user
  # if they don't exist in the database!
  robot.adapter.bot.addListener 'join', (channel, username, message) ->
    handleUser username

  # As a backup, listen to messages. Create a user if they don't exist in
  # the database!
  robot.adapter.bot.addListener 'message', (from, to, message) ->
    handleUser from unless from is 'jtv'
