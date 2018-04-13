require "json"
require "yaml"

class Config
  JSON.mapping({
    text_colors: {type: Bool, key: "textColors", default: true},
    punch_path:  {type: String, key: "punchPath", default: "#{ENV["HOME"]}/.punch/punches", getter: false, setter: false},
    user:        Person,
    clients:     Hash(String, Person),
    projects:    Hash(String, Project),
    sync:        SyncSettings,
  })

  @@instance : Config?

  getter config_path : String?
  setter config_path : String?

  def self.instance
    @@instance.as(Config)
  end

  def punch_path
    if !@config_path.nil? && @punch_path[0] == '.'
      File.join File.dirname(@config_path.as(String)), @punch_path[1..@punch_path.size]
    else
      @punch_path
    end
  end

  def self.load(path : String) : Config
    conf = Config.from_json File.read(path)
    conf.config_path = path
    @@instance = conf
    conf
  end
end

# ====================== #
#     CONFIG CLASSES     #
# ====================== #

class Address
  JSON.mapping({
    street: String,
    city:   String,
    state:  String,
    zip:    String,
  })
end

class Person
  JSON.mapping({
    name:    String,
    company: {type: String, nilable: true},
    address: {type: Address, nilable: true},
  })
end

class Project
  JSON.mapping({
    name:        String,
    description: {type: String, nilable: true},
    hourly_rate: {type: Float64, default: 0.0, key: "hourlyRate"},
    client:      {type: String | Person, nilable: true},
  })
end

class SyncSettings
  JSON.mapping({
    auto_sync: {type: Bool, key: "autoSync"},
  })
end
