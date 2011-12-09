# General purpose helper and utility methods.

Util =
  # Turns 3600 seconds into '1:00' (hours and minutes).
  formatSecondsAsTime: (seconds) ->
    secondsInt = parseInt(seconds, 10)
    hours = parseInt(secondsInt / 60 / 60, 10)
    minutes = parseInt((secondsInt / 60) % 60, 10)
    hoursString = if hours > 0 then hours else ''
    minutesString = if minutes > 9 then minutes else '0' + minutes
    hoursString + ':' + minutesString

  # Helper function to escape a string for HTML rendering.
  # Looted from backbone.js.
  escapeHTML: (string) ->
    string.replace(/&(?!\w+;|#\d+;|#x[\da-f]+;)/gi, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')

  formatDateAsTitle: (date) ->
    date.toLocaleDateString()

@app = window.app || {}
@app.Util = Util
