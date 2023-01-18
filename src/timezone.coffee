# Description:
#   Enable hubot to convert timezones for you.
#
# Dependencies:
#   "moment": "^2.10.3"
#
# Commands:
#   hubot time in <location> - Ask hubot for a time in a location
#   hubot <time> in <location> - Convert a given time to a given location, e.g. "1pm in Sydney"
#   hubot <time> from <location> to <location> - Convert a given time between 2 locations
#   hubot set timezone offset to <offset> - Set the default timezone offset, can be hours or minutes
#
# Notes:
#   The default timezone offset is used in the `hubot <time> in <location>` command.
#   If not set, it'll fall back to hubot server's timezone.

querystring = require('querystring')
moment = require('moment')

parseTime = (timeStr) ->
  m = moment.utc(timeStr, [
    'ha', 'h:ma',
    'YYYY-M-D ha', 'YYYY-M-D h:ma',
    'YYYY-D-M ha', 'YYYY-D-M h:ma',
    'M-D-YYYY ha', 'M-D-YYYY h:ma',
    'D-M-YYYY ha', 'D-M-YYYY h:ma'
  ], true)
  return if m.isValid() then m.unix() else null

formatTime = (timestamp) ->
  return moment.utc(timestamp).format('dddd, MMMM Do YYYY, h:mm:ss a')

# Use Google's Geocode and Timezone APIs to get timezone offset for a location.
getTimezoneInfo = (res, timestamp, location, callback) ->
  q = querystring.stringify({ 
    key: process.env.HUBOT_GOOGLE_MAPS_KEY,
    address: location, 
    sensor: false 
  })

  res.http('https://maps.googleapis.com/maps/api/geocode/json?' + q)
    .get() (err, httpRes, body) ->
      if err
        callback(err, null)
        return

      json = JSON.parse(body)
      if json.results.length == 0
        callback(new Error('no address found'), null)
        return

      latlong = json.results[0].geometry.location
      formattedAddress = json.results[0].formatted_address
      tzq = querystring.stringify({
        key: process.env.HUBOT_GOOGLE_MAPS_KEY,
        location: latlong.lat + ',' + latlong.lng,
        timestamp: timestamp,
        sensor: false
      })

      res.http('https://maps.googleapis.com/maps/api/timezone/json?' + tzq)
        .get() (err, httpRes, body) ->
          if err
            callback(err, null)
            return

          json = JSON.parse(body)
          if json.status != 'OK'
            callback(new Error('no timezone found'))
            return

          callback(null, {
            formattedAddress: formattedAddress,
            dstOffset: json.dstOffset,
            rawOffset: json.rawOffset
          })

# Convert time between 2 locations and send back the results.
# If `fromLocation` is null, send back time in `toLocation`.
convertTime = (res, timestamp, fromLocation, toLocation) ->
  sendLocalTime = (utcTimestamp, location) ->
    getTimezoneInfo res, utcTimestamp, location, (err, result) ->
      if (err)
        res.send("I can't find the time at #{location}.")
      else
        localTimestamp = (utcTimestamp + result.dstOffset + result.rawOffset) * 1000
        res.send("Time in #{result.formattedAddress} is #{formatTime(localTimestamp)}")

  if fromLocation
    getTimezoneInfo res, timestamp, fromLocation, (err, result) ->
      if (err)
        res.send("I can't find the time at #{fromLocation}.")
      else
        utcTimestamp = timestamp - result.dstOffset - result.rawOffset
        sendLocalTime(utcTimestamp, toLocation)
  else
    sendLocalTime(timestamp, toLocation)

module.exports = (robot) ->
  robot.respond /set timezone offset to (-?\d+)/i, (res) ->
    offset = parseInt(res.match[1], 10)
    if -16 < offset && offset < 16
      # offset is in hours
      offset = offset * 60
    robot.brain.data.timezoneOffset = offset
    res.send("Default timezone offset is set to #{offset}")

  robot.respond /(.*) from (.*) to (.*)/i, (res) ->
    timestamp = parseTime(res.match[1])
    return unless timestamp
    convertTime(res, timestamp, res.match[2], res.match[3])

  robot.respond /(.*) in (.*)/i, (res) ->
    requestedTime = res.match[1]
    defaultOffset = robot.brain.data.timezoneOffset || moment().utcOffset()
    if requestedTime == 'time'
      timestamp = moment().unix()
    else if parseTime(requestedTime)
      timestamp = parseTime(requestedTime) - defaultOffset * 60
    else
      return
    convertTime(res, timestamp, null, res.match[2])
