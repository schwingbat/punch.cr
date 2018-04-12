require "json"
require "yaml"

class Config
  JSON.mapping({
    text_colors: {type: Bool, key: "textColors", default: true},
    punch_path:  {type: String, key: "punchPath", default: "#{ENV["HOME"]}/.punch/punches"},
    user:        Person,
    clients:     Hash(String, Person),
    projects:    Hash(String, Project),
    sync:        SyncSettings,
  })

  INSTANCE    = load
  CONFIG_PATH = "#{ENV["HOME"]}/.punch/punchconfig.json"

  def self.instance
    INSTANCE
  end

  def self.load
    Config.from_json File.read(CONFIG_PATH)
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
