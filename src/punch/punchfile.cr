require "json"
require "./config"

class Punchfile
  JSON.mapping({
    created: { type: Time, nilable: true, converter: Time::EpochMillisConverter },
    updated: { type: Time, nilable: true, converter: Time::EpochMillisConverter },
    punches: Array(Session)
  })

  def punch_in(project : String)
    @sessions << Session.new(project: project)
  end

  def self.read_from_json(path : String): Punchfile
    self.from_json File.read(path)
  end

  def self.latest_punch_for(*, project : String)
    get_punchfile_list.sort.reverse.each do |path|
      puts path
    end
  end

  def self.all_punches
    sessions = [] of Session
    self.all.each do |file|
      file.punches.each do |session|
        sessions << session
      end
    end
    return sessions
  end

  def self.all
    config = Config.instance
    punchfiles = [] of Punchfile

    Dir.children(config.punch_path).each do |filename|
      path = File.join config.punch_path, filename
      punchfiles << Punchfile.read_from_json path
    end

    return punchfiles
  end
end