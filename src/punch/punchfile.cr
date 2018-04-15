require "json"
require "./config"

class Punchfile
  JSON.mapping({
    created:  {type: Time, converter: Time::EpochMillisConverter, default: Time.now},
    updated:  {type: Time, converter: Time::EpochMillisConverter, default: Time.now},
    sessions: {type: Array(Session), key: "punches", default: [] of Session, getter: false},
  })

  def initialize(time = Time.now)
    @created = time
    @updated = time
    @sessions = [] of Session
  end

  def punch_in(project : String, *, autosave = false)
    session = Session.new(project: project)
    @sessions << session
    save if autosave
  end

  def punch_out(project : String, *, autosave = false)
    punched_in = @sessions.find { |s| s.project == project && s.punched_in? }

    if punched_in
      punched_in.out = Time.now
    else
      raise Exception.new("No open session exists for project #{project}")
    end
    save if autosave
  end

  def sessions
    @sessions.each do |session|
      session.punchfile = self
    end
    @sessions.sort_by! &.in

    @sessions
  end

  def file_path
    File.join Config.instance.punch_path, Punchfile.name_for_time(@created)
  end

  def save
    @updated = Time.now
    File.write file_path, to_json
  end

  def total_pay
    config = Config.instance
    pay = 0
    @sessions.each do |session|
      if config.projects[session.project]?
        pay += session.duration.total_hours * config.projects[session.project].hourly_rate
      end
    end
    pay
  end

  def total_time
    @sessions.reduce(Time::Span.new(nanoseconds: 0)) do |time, session| 
      time += session.duration
    end
  end

  # *====================* #
  #         Static         #
  # *====================* #

  def self.name_for_time(time : Time)
    "punch_#{time.year}_#{time.month}_#{time.day}.json"
  end

  def self.read_from_json(path : String) : Punchfile
    self.from_json File.read(path)
  end

  def self.read_or_create_for_time(time : Time)
    if file = read_for_date?(time)
      file
    else
      new(time)
    end
  end

  def self.read_for_date(time : Time)
    name = name_for_time(time)
    path = File.join(Config.instance.punch_path, name)
    read_from_json(path)
  end

  def self.read_for_date?(time : Time)
    begin
      read_for_date(time)
    rescue
      nil
    end
  end

  def self.latest_punch_for(*, project : String)
    get_punchfile_list.sort.reverse.each do |path|
      puts path
    end
  end

  def self.all_sessions
    self.all.flat_map &.sessions
  end

  def self.all
    config = Config.instance
    punchfiles = [] of Punchfile

    Dir.children(config.punch_path).each do |filename|
      next unless File.extname(filename) == ".json"

      path = File.join config.punch_path, filename
      begin
        punchfiles << Punchfile.read_from_json path
      rescue err
        puts "❗  Failed to read #{filename}: #{err}".colorize(:yellow)
      end
    end

    return punchfiles
  end
end
