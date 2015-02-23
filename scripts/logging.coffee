# Description:
#   Functionality around logging to the Avalonstar(tv) API.

# Firebase.
Firebase = require 'firebase'
firebase = new Firebase 'https://avalonstar.firebaseio.com/'

# Firebase keys.
viewers = firebase.child('viewers')

module.exports = (robot) ->
  # handleUser().
  handleUser = (username) ->
    # First, we need to fill the robot's brain with a viewer object.
    unless robot.brain.data.viewers[username]?
      robot.brain.data.viewers[username] = {'name': username}
      robot.logger.debug "#{username} has been added to the brain."

    # Check if we have a user on Firebase. If not, create it.
    viewers.child(username).once 'value', (snapshot) ->
      unless snapshot.val()?
        robot.http("https://api.twitch.tv/kraken/users/#{username}").get() (err, res, body) ->
          json = {'display_name': body.display_name or username, 'username': username}
          viewers.child(username).set json, (error) ->
            robot.logger.debug "#{username} has been added to Firebase."

  # handleMessage().
  handleMessage = (message, data, is_emote) ->
    # The meat of the entire operation. Pushes a payload containing a message,
    # emotes, roles, and usernames to Firebase.
    firebase.child('viewers').child(data.name).once 'value', (snapshot) ->
      timestamp = Firebase.ServerValue.TIMESTAMP
      firedata = snapshot.val() or []
      chatroles = data.roles or []
      roles = firedata?.roles or []

      json =
        # User data.
        'username': data.name
        'display_name': firedata?.display_name or data.name
        'color': firedata?.color or '#ffffff'
        'roles': roles.concat chatroles

        # Message data.
        'timestamp': timestamp
        'message': message
        'emotes': firedata?.emotes or []
        'is_emote': is_emote

      # Send the message to Firebase!
      messages = firebase.child('messages').push()
      messages.setWithPriority json, timestamp

  robot.enter (msg) ->
    # Use TWITCHCLIENT 3.
    robot.adapter.command 'twitchclient', '3'

    # Reset Hubot's autosave interval to 30s instead of 5.
    # This is to prevent unnecessary reloading of old data. :(
    robot.brain.resetSaveInterval 30

  # Use this when there's support for IRCv3 somewhere in Nodeland.
  # robot.enter (msg) ->
  #   robot.adapter.command 'CAP', 'REQ', 'twitch.tv/tags'

  # Listeners. The below functions allow us to distinguish emotes from messages
  # which, unfortunately, neither Hubot nor Hubot IRC do natively.
  robot.adapter.bot.addListener 'action', (from, to, message) ->
    unless from is 'jtv'
      # If the user emotes, set json.emote to true.
      handleUser from
      handleMessage message, robot.brain.userForName(from), true

  robot.adapter.bot.addListener 'message', (from, to, message) ->
    unless from is 'jtv'
      # Listen for general messages.
      handleUser from
      handleMessage message, robot.brain.userForName(from), false

  # Listening for special users (e.g., turbo, staff, subscribers)
  # Messages can be prefixed by a username (most likely the bot's name).
  # Note: Roles such as moderator do not appear in this method.
  robot.hear /.*?\s?SPECIALUSER ([a-zA-Z0-9_]*) ([a-z]*)/, (msg) ->
    if msg.envelope.user.name is 'jtv'
      name = msg.match[1]
      userdata = robot.brain.data['viewers'][name]
      userdata['roles'] ?= []

      if msg.match[2] not in userdata['roles']
        userdata['roles'].push msg.match[2]
      robot.brain.save()

      # Save user list to Firebase.
      viewers.child(name).child('roles').set userdata['roles'], (error) ->
        robot.logger.error "Error in `handleRoles`: #{error}" if error

  # Listening for emoticon sets.
  # Expected value is a list of integers.
  robot.hear /EMOTESET ([a-zA-Z0-9_]*) (.*)/, (msg) ->
    if msg.envelope.user.name is 'jtv'
      emotes = msg.match[2].substring(1).slice(0, -1).split(',')  # Store EMOTESET as an actual list?

      # Save emote list to Firebase.
      viewers.child(msg.match[1]).child('emotes').set emotes, (error) ->
        console.log "handleEmotes: #{error}" if error?

  # Listening for a user's color.
  # Expected value is a hex code.
  robot.hear /USERCOLOR ([a-zA-Z0-9_]*) (#[A-Z0-9]{6})/, (msg) ->
    if msg.envelope.user.name is 'jtv'
      # Save user list to Firebase.
      viewers.child(msg.match[1]).child('color').set msg.match[2], (error) ->
        robot.logger.error "Error in `handleColor`: #{error}" if error

  # Listening to see if a user gets timed out.
  # Expected value is a username.
  robot.hear /CLEARCHAT ([a-zA-Z0-9_]*)/, (msg) ->
    viewer = msg.match[1]
    messages = firebase.child('messages')

    # CLEARCHAT without a name will clear the entire chat on Twitch web. Do not
    # respect that, lest we purge things that we don't want to purge.
    if viewer
      # Find the last five messages from the user to purge (we don't choose
      # more because a purge will rarely cover that many lines).
      messages.orderByChild('username').endAt(viewer).limitToLast(10).once 'value', (snapshot) ->
        snapshot.forEach (message) ->
          # Because of Firebase quirks, if it finds less than 5 results for the
          # viewer, it will find similarly spelled results. Let's not purge the
          # wrong viewer please.
          username = message.child('username').val()
          if username is viewer
            robot.logger.debug "\"#{message.child('message').val()}\" by #{username} has been purged."
            message.ref().child('is_purged').set(true)
