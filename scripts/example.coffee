Redis = require("redis")
redisClient = Redis.createClient()
alertRoomJID = process.env.HUBOT_HIPCHAT_TEMP_ALERT_ROOM_JID

module.exports = (robot) ->

  setInterval =>
    robot.http("http://private-b32ed-temperatureapiforspribot.apiary-mock.com/latest")
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        data = JSON.parse body
        redisClient.hmset 'spribot:office_temp',
          temp: data.temp
          timestamp: data.timestamp
  , 10000

  setInterval =>
    redisClient.hgetall 'spribot:office_temp', (err, object) ->
      if parseFloat(object.temp) > 28.0
        redisClient.exists 'spribot:office_temp_alert_timeout', (err, reply) ->
          if reply == 1
            #do nothing. wait :)
          else
            redisClient.set 'spribot:office_temp_alert_timeout', true
            redisClient.expire 'spribot:office_temp_alert_timeout', 300
            robot.messageRoom alertRoomJID, "#{object.temp}° C Its getting hot in here... Please consider decreasing the A/C temperature."
  , 60000


  robot.respond /temperature/i, (msg) ->
    redisClient.hgetall 'spribot:office_temp', (err, object) ->
      msg.reply "The temperature now is #{object.temp}° C. Reported at #{(new Date parseInt(object.timestamp)).toLocaleTimeString()}"

