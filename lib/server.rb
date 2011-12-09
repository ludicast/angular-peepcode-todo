require "./lib/init"
require "./lib/json_db"

class DemoApp < Sinatra::Base

  register Barista::Integration::Sinatra

  disable :logging
  set :root, File.dirname(__FILE__) + "/../"

  RETURN_HTTP_ERRORS_FOR_CLIENT_DEBUGGING = false

  before do
    # NOTE: Uncomment to simulate a slow network connection.
    # sleep 2
    @db = JSONDb.new "db-#{ENV['RACK_ENV']}.json"
  end

  get "/" do
    send_file "public/index.html", :type => 'text/html', :disposition => 'inline'
  end


  get "/inside.html" do
    send_file "public/inside.html", :type => 'text/html', :disposition => 'inline'
  end



  get "/tasks/:year/:month/:date" do |year, month, date|
    send_file "public/index.html", :type => 'text/html', :disposition => 'inline'
  end

  get "/favicon.ico" do
    ""
  end

  # Resources

  # Get a list of all records.
  # NOTE: For most apps, this should be scoped by user.
  get "/api/tasks" do
    content_type :json
    @db.members.to_json
  end

  get "/api/tasks/:year/:month/:date" do |year, month, date|
    content_type :json
		#puts @db.members
    tasks_for_today = @db.members.select do |task|
      # NOTE: JavaScript stores dates in milliseconds.
      time = Time.at task['createdAt'].to_i/1000
			puts time.year, time.month, time.day
      if time.year == year.to_i && time.month == month.to_i && time.day == date.to_i
        true
      else
        false
      end
    end
    tasks_for_today.to_json
  end

  # Get a single record.
  get "/api/tasks/:id" do |id|
    record = @db.get id

    content_type :json
    record.to_json
  end

  # Create a record.
  post "/api/tasks" do
    record = JSON.parse request.body.read
    record = @db.save_doc record
    @db.save

    content_type :json
    record.to_json
  end

  # Update a record.
  put "/api/tasks/:id" do |id|
    if RETURN_HTTP_ERRORS_FOR_CLIENT_DEBUGGING
      status 403
      return "ACCESS DENIED"
    end
    record = @db.get id
    record.merge! JSON.parse(request.body.read)
    @db.save

    content_type :json
    record.to_json
  end

  delete "/api/tasks/:id" do |id|
    @db.delete id
    @db.save
    [].to_json
  end

end
