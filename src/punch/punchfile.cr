require "json"
require "./config"

class Punchfile
  JSON.mapping({
    created: { type: Time, nilable: true, converter: Time::EpochMillisConverter },
    updated: { type: Time, nilable: true, converter: Time::EpochMillisConverter },
    punches: Array(Session)
  })

  def update
    self.updated = Time.now
  end

  def save
    # Write to JSON file
  end

  def punch_in(project : String)
    @sessions << Session.new(project: project)
    update
    save
  end

  def punch_out(project : String)
    punched = @sessions.find { |s| s.project == project && s.out == nil }

    puts punched
  end

  #*====================*#
  #        Static        #
  #*====================*#

  def self.read_from_json(path : String): Punchfile
    self.from_json File.read(path)
  end

  def self.read_or_create_for_time(time : Time)
    name = "punch_#{time.year}_#{time.month}_#{time.day}.json"
    path = File.join(Config.instance.punch_path, name)
    read_from_json(path)
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