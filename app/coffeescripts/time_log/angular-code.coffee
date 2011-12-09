class @Router
	constructor:($route)->
		d = new Date()
		year = d.getFullYear()
		month = d.getMonth()
		date = d.getDate()

		$route.when "/:year/:month/:date",
			template:"/inside.html", controller:TasksController
		$route.otherwise redirectTo: "/#{year}/#{month}/#{date}"

class @TasksController
	constructor:(@$xhr,@$routeParams,@$location)->
		{year, month, date} = $routeParams
		@currentDate = new Date(year, month, date)
		@$xhr "get",  "/api/tasks/#{year}/#{parseInt(month) + 1}/#{date}", (code, @tasks)=>

	# not sure is scoping makes sense, but seems like a plan
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

	hasStarted:(tasks = [])->
		(task for task in tasks when (task.title is "Start")).length > 0
	
	startTime:->


	createTask:(task)->
		@$xhr "post", "/api/tasks", task, (code, data)=>
			@tasks.push data

	addTask2:-> console.log ",,,"
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

	loadData:->
		@$location.path "/#{@currentDate.getFullYear()}/#{@currentDate.getMonth()}/#{@currentDate.getDate()}"

# implicitly inherits from tasks controller, how this messes up DI I can only guess
#
# note also double up on LI tags
#
# console.log is lost - is that wacky or what?
#
# $xhr split between this and superclass - problem
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
		@task.completedAt = @timeStamp()
		@update()

	unFinish:->
		@task.completedAt = null
		@update()

	update:->
		@$xhr "PUT", "/api/tasks/#{@task.id}", @task, ->
		
	checkSave:()->
		console.log "oooo"