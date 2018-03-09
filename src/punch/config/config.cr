require "json"
require "./config_json"

class Config
  include ConfigJSON

  getter projects : Hash(String, Project)
  getter clients : Hash(String, Person)
  getter user : Person

  INSTANCE = new

  def initialize
    if !has_json_config?
      puts "NO JSON CONFIG FILE"
    end

    config = read_json_config

    @user = config.user
    @clients = config.clients
    @projects = config.projects
    # @sync = config.sync
  end

  def punch_path
    "#{ ENV["HOME"] }/.punch/punches"
  end

  def self.instance
    INSTANCE
  end
end