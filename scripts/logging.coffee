# Description:
#   Functionality around logging to the Avalonstar(tv) API.

Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

module.exports = (robot) ->
  if robot.adapter.bot?
    # Listen to joins (which only happen on `TWITCHCLIENT 1`.), create a user
    # if they don't exist in the database!
    robot.adapter.bot.addListener 'join', (channel, who) ->
      # Check if we have a user on Firebase. If not, create it.
      viewers = firebase.child('viewers')
      viewers.child(username).once 'value', (snapshot) ->
        unless snapshot.val()?
          json =
            'username': username
          viewers.child(username).set json, (error) ->
            robot.logger.debug "We have new blood: #{who}." if !error?
