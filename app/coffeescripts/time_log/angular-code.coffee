class @Router
	constructor:($route)->
		d = new Date()
		year = d.getFullYear()
		month = d.getMonth()
		date = d.getDate()

		$route.when "/tasks/:year/:month/:date",
			template:"/inside.html", controller:TasksController
		$route.otherwise redirectTo: "/tasks/#{year}/#{month}/#{date}"

class @TasksController
	constructor:(@$xhr,@$routeParams,@$location)->
		{year, month, date} = $routeParams
		@currentDate = new Date(year, month, date)
		@$xhr "get",  "/api/tasks/#{year}/#{parseInt(month) + 1}/#{date}", (code, @tasks)=>
		setInterval (=> @$apply(->)), 1000

	TaskViewHelper:
		isCompleted:(task)-> !! task.completedAt
		isNotCompleted:(task)-> ! task.completedAt

	setTag:(obj)->
		matches = obj.title.match /\s#(\w+)/
		if matches?.length
			obj.tag = matches[1]
		else
			obj.tag = null
		obj

	timeStamp:-> (new Date).getTime()

	startTimer:->
		task = {tag:null, title:"Start", completedAt:@timeStamp(), duration:0, createdAt:@timeStamp()}
		@createTask task

	hasStarted:->
		(task for task in (@tasks or []) when (task.title is "Start")).length > 0

	timeSinceStart:->


	createTask:(task)->
		@$xhr "post", "/api/tasks", task, (code, data)=>
			@tasks.push data

	addTask:->
		@createTask @setTag(title:@newTaskValue,createdAt:@timeStamp())
		@newTaskValue = ""

	previousDate:->
		@currentDate.setDate(@currentDate.getDate() - 1)
		@loadData()
	goToToday:->
		@currentDate = new Date()
		@loadData()
	nextDate:->
		@currentDate.setDate(@currentDate.getDate() + 1)
		@loadData()

	isToday: ->
		today = new Date()
		@currentDate.getFullYear() is today.getFullYear() and
		@currentDate.getMonth() is today.getMonth() and
		@currentDate.getDate() is today.getDate()

	loadData:->
		@$location.path "/tasks/#{@currentDate.getFullYear()}/#{@currentDate.getMonth()}/#{@currentDate.getDate()}"

	totalDurations:(condition)->
		condition ||= (->true)
		duration = 0
		for task in (@tasks or [])
			if task.duration and condition(task)
				duration += task.duration
		duration

	totalUntagged:->
		totalDurations ((task)-> task.tag is null or task.tag.length < 1)

	totalTagged:(tag)->
		totalDurations ((task)-> task.tag is tag)

	lastCompletedAt:->
		maxCompletedAt = 0
		for task in (@tasks or [])
			if task.completedAt and task.completedAt > maxCompletedAt
				maxCompletedAt = task.completedAt
		maxCompletedAt

	timeSinceStart:->
		Math.floor((@timeStamp() - @lastCompletedAt()) / 1000)

TasksController.$inject = ['$xhr', '$routeParams', '$location']

class @TaskController
	saveTitle:->
		@setTag @task
		@task.editing = false
		@update()
				
	destroy:->
		@$xhr "DELETE", "/api/tasks/#{@task.id}", (code)=>
			@task.deleted = true

	undoDelete:->
		@task.deleted = false
		angular.Array.remove(@tasks, @task)
		@createTask @task

	finish:->
		@task.duration = Math.floor((@timeStamp() - @lastCompletedAt()) / 1000)
		@task.completedAt = @timeStamp()
		@update()

	unFinish:->
		@task.completedAt = null
		@task.duration = null
		@update()

	update:->
		@$xhr "PUT", "/api/tasks/#{@task.id}", @task, ->
		
angular.filter 'formatSecondsAsTime', (seconds) ->
    secondsInt = parseInt(seconds, 10)
    hours = parseInt(secondsInt / 60 / 60, 10)
    minutes = parseInt((secondsInt / 60) % 60, 10)
    hoursString = if hours > 0 then hours else ''
    minutesString = if minutes > 9 then minutes else '0' + minutes
    hoursString + ':' + minutesString

angular.service '$locationConfig', ->
	{html5Mode: true}
