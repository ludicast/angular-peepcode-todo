# MODELS

class Task extends Backbone.Model
  defaults:
    tag: ''
  url: ->
    # NOTE: Overridden here since collection URL is custom with a date.
    if @id
      "/api/tasks/#{@id}"
    else
      "/api/tasks"
  initialize: (attributes, options) ->
    if !attributes.createdAt
      @attributes.createdAt = (new Date).getTime()
    if tag = @extractTag(attributes.title)
      @attributes.tag = tag
    else
      @attributes.tag = null
    @bind 'change:title', @updateTag, @
  validate: (attributes) ->
    # NOTE: attributes argument is ONLY the ones that changed.
    mergedAttributes = _.extend(_.clone(@attributes), attributes)
    if !mergedAttributes.title or mergedAttributes.title.trim() == ''
      return "Task title must not be blank."
  updateTag: (model, newTitle) ->
    if tag = @extractTag(newTitle)
      @set tag:tag
    else
      @set tag:null
  extractTag: (text) ->
    if @attributes.title
      matches = @attributes.title.match /\s#(\w+)/
      if matches?.length
        return matches[1]
    ''
  markComplete: ->
    completedAt = (new Date).getTime()
    duration    = 0
    if @collection
      mostRecentCompletedTask = _.last(@collection.completedTasks())
      if mostRecentCompletedTask
        durationInMilliseconds = (completedAt - mostRecentCompletedTask.get('completedAt'))
        floatDurationSeconds = durationInMilliseconds / 1000
        duration = parseInt floatDurationSeconds, 10
    @set completedAt:completedAt, duration:duration
  markIncomplete: ->
    @set completedAt:null, duration:0
  isCompleted: ->
    # Returns truthy if the task is done.
    @attributes.completedAt

@app = window.app ? {}
@app.Task = Task

# NOTE: For compatibility with Node.js on the server:
#root = exports ? this
#root.Task = Task

