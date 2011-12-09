app = window.app ? {}

# slide down a pipe
# punch a brick
# eat a mushroom
# throw a fireball
# save the princess

# Asserts that a number of epoch seconds is within the last 5 seconds.
#
#   expect(createdAt).toBeRecent()
jasmine.Matchers.prototype.toBeRecent = ->
  @actual > ((new Date).getTime() - 5)


describe "Task", ->

  describe "new task", ->
    beforeEach ->
      @task = new app.Task
        title: 'punch a brick'

    it "populates title", ->
      expect(@task.get('title')).toEqual 'punch a brick'

    it "sets created at date", ->
      expect(@task.get('createdAt')).toBeRecent()

    it "sets tag to empty", ->
      expect(@task.get('tag')).toEqual(null)

    it "is not completed", ->
      expect(@task.isCompleted()).toBeFalsy()

  describe "task with tag", ->
    beforeEach ->
      @task = new app.Task
        title: 'eat a mushroom #lunch'

    it "extracts tag", ->
      expect(@task.get('tag')).toEqual('lunch')

  describe "task completion", ->
    beforeEach ->
      @task = new app.Task
        title: 'throw a fireball'
      @task.markComplete()

    it "marks as completed", ->
      expect(@task.isCompleted()).toBeTruthy()

    it "marks as uncompleted", ->
      @task.markIncomplete()
      expect(@task.isCompleted()).toBeFalsy()

  describe "task collection duration calculations", ->
    resetDb = ->
      databaseName = 'test-Tasks'
      delete localStorage.getItem(databaseName)
      app.Tasks.localStorage = new Store(databaseName)

    beforeEach ->
      resetDb()
      app.Tasks.create title: 'Start'
      app.Tasks.first().markComplete()
      @task = app.Tasks.first()

    it "populates duration for first event", ->
      expect(@task.isCompleted()).toBeTruthy()
      expect(@task.get('duration')).toEqual(0)

    it "populates duration for subsequent events", ->
      @task.set { completedAt:((new Date).getTime() - 60 * 1000) }
      app.Tasks.create title: 'throw a fireball'
      mostRecentTask = app.Tasks.last()
      mostRecentTask.markComplete()
      expect(mostRecentTask.get('duration')).toEqual(60)

    it "calculates total duration seconds for all completed tasks", ->
      @task.set completedAt:(new Date).getTime(), duration:0
      for i in [1,2,3]
        app.Tasks.create
          title: 'throw a fireball'
          completedAt:(new Date).getTime()
          duration: i*15*60
      expect(app.Tasks.duration()).toEqual 91*60

describe "Util", ->

  describe "formats seconds as time", ->

    it "with less than 10 minutes", ->
      result = app.Util.formatSecondsAsTime 6*60
      expect(result).toEqual ':06'

    it "with less than an hour", ->
      result = app.Util.formatSecondsAsTime 45*60
      expect(result).toEqual ':45'

    it "with more than an hour", ->
      result = app.Util.formatSecondsAsTime 60*60
      expect(result).toEqual '1:00'

    it "with much more than an hour", ->
      result = app.Util.formatSecondsAsTime 75*60
      expect(result).toEqual '1:15'

