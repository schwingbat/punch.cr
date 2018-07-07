require "kemal"
require "json"

class APIResponse
  @code : Int32
  @data : String

  def initialize(@code = 204, @data = "{}")
  end

  def to_s
    JSON.build do |json|
      json.object do
        json.object "meta" do
          json.field "code", @code
        end
        json.field "data", @data
      end
    end
  end
end

class APIErrorResponse
  @code : Int32
  @errors : Array(String)

  def initialize(@code, @errors)
  end

  def to_s
    JSON.build do |json|
      json.object do
        json.object "meta" do
          json.field "code", @code
        end
        json.array "errors", @errors
      end
    end
  end
end

module Server
  static_headers do |response, filepath, filestat|
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add("Content-Size", filestat.size.to_s)
  end

  before_all "/api/*" do |env|
    env.response.content_type = "application/json"
    env.response.headers.add("Access-Control-Allow-Origin", "*")
  end

  post "/api/punch_in/:project" do |env|
    APIResponse.new(204)
  end

  post "/api/punch_out" do |env|
    APIResponse.new(204)
  end

  get "/api/config" do
    Config.instance.to_json
  end

  get "/" do
    "It works!"
  end

  def self.start(port = 5555)
    puts "Running Punch server on port #{port}"
    Kemal.run port
  end
end
