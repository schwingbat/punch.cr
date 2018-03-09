require "json"

class Address
  JSON.mapping({
    street: String,
    city: String,
    state: String,
    zip: String
  })
end

class Person
  JSON.mapping({
    name: String,
    company: { type: String, nilable: true },
    address: { type: Address, nilable: true }
  })
end

class Project
  JSON.mapping({
    name: String,
    description: { type: String, nilable: true },
    hourlyRate: { type: Float64, default: 0.0 },
    client: { type: String | Person, nilable: true }
  })
end

class JSONConfig
  JSON.mapping({
    user: Person,
    clients: Hash(String, Person),
    projects: Hash(String, Project),
  })
end

module ConfigJSON
  def json_config_path
    "#{ ENV["HOME"] }/.punch/punchconfig.json"
  end

  def has_json_config?
    File.exists? json_config_path
  end

  def read_json_config
    return JSONConfig.from_json File.read(json_config_path)
  end
end