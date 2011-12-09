# VIEWS

jQuery ->
  class AppView extends Backbone.View
    el: '#wrap'
    initialize: (options) ->
      @collection.bind 'reset', @render, @
      @subviews = [
        new MenuView      collection: @collection
        new DateTitleView collection: @collection
        new TasksView     collection: @collection
        new NewTaskView   collection: @collection
        ]
    render: ->
      $(@el).empty()
      $(@el).append subview.render().el for subview in @subviews
      @

  class MenuView extends Backbone.View
    tagName: 'nav'
    template: _.template($('#menu-template').html())
    events:
      'click .previous': 'goToPreviousDate'
      'click .today':    'goToToday'
      'click .next':     'goToNextDate'
    render: ->
      $(@el).html @template()
      @delegateEvents()
      @
    goToPreviousDate: (event) ->
      @collection.goToPreviousDate()
    goToToday: (event) ->
      @collection.setDate new Date
    goToNextDate: (event) ->
      @collection.goToNextDate()


  class DateTitleView extends Backbone.View
    template: _.template($('#date-title-template').html())
    render: ->
      $(@el).html @template(@collection.metaData())
      @


  class TasksView extends Backbone.View
    className: 'tasks'
    template: _.template($('#tasks-template').html())
    blankStateTemplate: _.template($('#blank-state-template').html())
    events:
      'click .start-tracking': 'startTracking'
    initialize: (options) ->
      @completedSubviews = [
        new CompletedTasksView collection: @collection
        new ClocksView collection: @collection
        new ElapsedClockView collection: @collection
        ]
      @incompleteSubviews = [
        new IncompleteTasksView collection: @collection
        ]
      @collection.bind 'start', @render, @
    render: ->
      if @collection.hasStarted()
        # Show CompletedTasksView, ClocksView, and ElapsedClockView
        $(@el).html @template()
        $(@el).append subview.render().el for subview in @completedSubviews
        if @collection.isToday()
          @$('.elapsed-clock').show()
        else
          @$('.elapsed-clock').hide()
      else
        # Show blank template with START button
        $(@el).html @blankStateTemplate()
        unless @collection.isToday()
          @$('.message-blank').text('No tasks were tracked on this day.')

      # In all cases, show IncompleteTaskView
      $(@el).append subview.render().el for subview in @incompleteSubviews

      # People shouldn't be able to check off items if the day hasn't started.
      unless @collection.hasStarted()
        @$('.is-done').prop 'disabled', true

      @delegateEvents()
      @
    startTracking: ->
      @collection.createStartTask()
      $('#new-task').val('').focus()


  class ElapsedClockView extends Backbone.View
    className: 'elapsed-clock'
    template: _.template($('#elapsed-clock-template').html())
    initialize: ->
      @collection.bind 'change', @render, @
    render: ->
      $(@el).html @template elapsedSeconds:@collection.secondsSinceLastTaskWasCompleted()
      setTimeout =>
        @render()
      , 1000*60
      @


  class ClocksView extends Backbone.View
    className: 'clocks'
    template: _.template($('#clocks-template').html())
    initialize: ->
      @collection.bind 'change', @render, @
    render: ->
      $(@el).html @template @collection.metaData()
      @


  class CompletedTasksView extends Backbone.View
    id: 'completed-tasks'
    tagName: 'ul'
    initialize: ->
      @collection.bind 'change', @render, @
      @collection.bind 'add',    @render, @
      @collection.bind 'remove', @render, @
    render: ->
      $(@el).empty()
      for task in @collection.completedTasks()
        completedTaskView = new CompletedTaskView model: task
        $(@el).append completedTaskView.render().el
        if @collection.completedTasks().length is 1
          completedTaskView.disable()
        else
          if task == _.last(@collection.completedTasks())
            completedTaskView.enable()
          else
            completedTaskView.disable()
      @

  class CompletedTaskView extends Backbone.View
    className: 'task'
    tagName: 'li'
    template: _.template($('#completed-task-template').html())
    render: ->
      $(@el).html @template(@model.toJSON())
      @
    disable: ->
      @$('input').prop 'disabled', true
    enable: ->
      @$('input').prop 'disabled', false
    events:
      'click input.is-done': 'markComplete'
    markComplete: ->
      if @$('.is-done').prop('checked')
        @model.markComplete()
      else
        @model.markIncomplete()
      @model.save()


  class IncompleteTasksView extends Backbone.View
    id: 'tasks-to-complete'
    tagName: 'ul'
    initialize: (options) ->
      @collection.bind 'add',     @render, @
      @collection.bind 'change',  @render, @
      @collection.bind 'destroy', @render, @
    render: ->
      $(@el).empty()
      for task in @collection.incompleteTasks()
        incompleteTaskView = new IncompleteTaskView model: task
        $(@el).append incompleteTaskView.render().el
      if @collection.undoItem()
        undoView = new UndoView collection: @collection
        $(@el).append undoView.render().el
      @


  class IncompleteTaskView extends Backbone.View
    className: 'task'
    tagName: 'li'
    template: _.template($('#incomplete-task-template').html())
    render: ->
      $(@el).html @template(@model.toJSON())
      @
    events:
      'click input.is-done': 'markComplete'
      'click .destroy':      'destroy'
      'click .edit':         'edit'
      'keypress .edit-task': 'saveOnEnter'
    markComplete: ->
      if @$('.is-done').prop('checked')
        @model.markComplete()
      else
        @model.markIncomplete()
      @model.save()
    edit: ->
      $(@el).html @make 'input', type:'text', class:'edit-task', value:@model.get('title')
      @$('.edit-task').focus()
    saveOnEnter: (event) ->
      if (event.keyCode is 13) # ENTER
        @model.save title:@$('.edit-task').val()
        @render()
    destroy: ->
      @model.destroy()


  class UndoView extends Backbone.View
    id: 'undo-template'
    className: 'task'
    tagName: 'li'
    events:
      'click .undo-button': 'applyUndo'
    template: _.template($('#undo-template').html())
    render: ->
      $(@el).html @template @collection.undoItem()
      @
    applyUndo: ->
      @collection.applyUndo()


  class NewTaskView extends Backbone.View
    tagName: 'form'
    template: _.template($('#new-task-template').html())
    events:
      'keypress #new-task': 'saveOnEnter'
      'focusout #new-task': 'hideWarning'
    render: ->
      if @collection.isToday()
        $(@el).html @template()
        @delegateEvents()
      else
        $(@el).empty()
      @
    saveOnEnter: (event) ->
      if (event.keyCode is 13) # ENTER
        event.preventDefault()
        newAttributes = {title:$('#new-task').val()}
        errorCallback = {error:@flashWarning}
        if @collection.create(newAttributes, errorCallback)
          @hideWarning()
          @focus()
    focus: ->
      $('#new-task').val('').focus()
    hideWarning: ->
      $('#warning').hide()
    flashWarning: (model, error) =>
      console.log error
      $('#warning').fadeOut(100)
      $('#warning').fadeIn(400)


  @app = window.app ? {}
  @app.AppView = AppView

