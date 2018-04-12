require "kemal"

module Server
  before_all "/api" do |env|
    env.response.content_type = "application/json"
  end

  get "/api/hello" do
    "It works!"
  end

  def self.start(port = 5555)
    puts "Running Punch server on port #{port}"
    Kemal.run port
  end
end
