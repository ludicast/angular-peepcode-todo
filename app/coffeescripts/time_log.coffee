@app = window.app ? {}

jQuery ->
  setupErrorHandlers = ->
    $(document).ajaxError (error, xhr, settings, exception) ->
      # NOTE: Status will be 0 if the server is unreachable.
      console.log xhr.status, xhr.responseText, "EXCEPTION: " + exception
      message = if xhr.status == 0
                  "The server could not be contacted."
                else if xhr.status == 403
                  "Login is required for this action."
                else if 500 <= xhr.status <= 600
                  "There was an error on the server."
      $('#error-message span').text message
      $('#error-message').slideDown()

  setupErrorHandlers()
  @app.router = new app.TimeLogRouter
  Backbone.history.start({pushState:true})


