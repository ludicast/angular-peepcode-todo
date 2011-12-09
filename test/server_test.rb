ENV['RACK_ENV'] = 'test'

$: << File.dirname(__FILE__) + "/../lib"
require "init"

require "minitest/autorun"
require "rack/test"

require "server"

Barista.logger.level = Logger::WARN

module DBSetup

  def setup_db
    @db = JSONDb.new("db-#{ENV['RACK_ENV']}.json")
    @db.delete!
  end

end

describe DemoApp do

  include Rack::Test::Methods
  include DBSetup

  before { setup_db }
  after  { setup_db }

  def app
    DemoApp.new
  end

  describe "/" do

    before do
      get "/"
    end

    it "responds with success" do
      assert_equal 200, response.status
    end

    it "emits HTML header" do
      assert_equal "text/html;charset=utf-8", response.headers['Content-type']
    end

  end

  describe "List tasks (GET /tasks)" do

    before do
      post "/api/tasks", {:title => "eat a mushroom", :completedAt => Date.today}.to_json
      post "/api/tasks", {:title => "save the princess"}.to_json
      get "/api/tasks"
    end

    it "returns success" do
      assert_equal 200, response.status
    end

    it "emits records as JSON" do
      tasks = JSON.parse response.body
      assert_equal 2, tasks.length
      task = tasks[0]
      assert_equal "eat a mushroom", task['title']
    end

  end

  describe "Create a new task (POST /tasks)" do

    before do
      post "/api/tasks", {:title => "save the princess"}.to_json
    end

    it "returns new record" do
      record = JSON.parse response.body
      assert_equal "save the princess", record['title']
      assert record['id'], "The record should have an id."
    end

    it "saves record to disk" do
      @db.load_data
      assert_equal 1, @db.members.length
      assert_equal "save the princess", @db.members[0]['title']
    end

  end

  describe "Get a single record (GET /tasks/:id)" do

    before do
      post "/api/tasks", {:title => "slide down a pipe"}.to_json
      record = JSON.parse response.body
      @id = record['id']
      assert @id, "The record should have an id."
      get "/api/tasks/#{@id}"
    end

    it "returns success" do
      assert_equal 200, response.status
    end

    it "returns a record" do
      record = JSON.parse response.body
      assert_equal "slide down a pipe", record['title']
    end

  end


  describe "Update a single record (PUT /tasks/:id)" do

    before do
      post "/api/tasks", {:title => "slide down a pipe"}.to_json
      record = JSON.parse response.body
      @id = record['id']
      assert @id, "The record should have an id."
      put "/api/tasks/#{@id}", {:title => "throw a fireball"}.to_json
    end

    it "returns success" do
      assert_equal 200, response.status
    end

    it "updates the record" do
      record = JSON.parse response.body
      assert_equal "throw a fireball", record['title']
    end

  end


  describe "Delete a single record (DELETE /tasks/:id)" do

    before do
      post "/api/tasks", {:title => "slide down a pipe"}.to_json
      record = JSON.parse response.body
      @id = record['id']
      assert @id, "The record should have an id."
      delete "/api/tasks/#{@id}"
    end

    it "returns success" do
      assert_equal 200, response.status
    end

    it "deletes the record" do
      @db.load_data
      assert_equal 0, @db.members.length
    end

  end


  alias_method :request,  :last_request
  alias_method :response, :last_response
end

describe JSONDb do

  include DBSetup

  before { setup_db }
  after  { setup_db }

  it "saves data" do
    @db.save_doc({:a => 1})
    @db.save
    assert_equal 1, @db.members.length
  end

end

