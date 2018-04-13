class Session
  property punchfile : Punchfile?

  TIME_FORMAT = "%l:%M%p"

  JSON.mapping({
    project:  String,
    in:       {type: Time, converter: Time::EpochMillisConverter, getter: false},
    out:      {type: Time, nilable: true, converter: Time::EpochMillisConverter, getter: false, emit_null: true},
    comments: {type: Array(String), setter: false},
  })

  def initialize(project : String)
    @project = project
    @in = Time.now
    @out = nil
    @comments = [] of String
  end

  def in
    @in.to_local
  end

  def out
    if @out
      @out.as(Time).to_local
    else
      nil
    end
  end

  def punch_out(time = Time.now)
    @out = time
  end

  def add_comment(comment : String)
    @comments << comment
  end

  def duration
    (@out || Time.now) - @in
  end

  def pay : Float
    config = Config.instance
    if (project = config.projects[@project]?) && project.hourly_rate
      duration.total_hours * project.hourly_rate
    else
      0.0
    end
  end

  def save
    @punchfile.as(Punchfile).save unless @punchfile.nil?
  end

  def punched_in?
    !@out
  end

  def to_log
    String.build do |s|
      time_in = in.to_s(TIME_FORMAT)

      if punched_in?
        time_out = "PRESENT".rjust(time_in.size).colorize(:green).mode(:bold)
      else
        time_out = out.as(Time).to_s(TIME_FORMAT).colorize(:cyan)
      end

      if project = Config.instance.projects[@project]?
        project_name = project.name
      else
        project_name = @project
      end

      s << "#{time_in.colorize(:cyan)} - #{time_out}" # Time range
      s << " [#{project_name}]".colorize(:yellow)     # Project label

      @comments.each do |comment|
        s << "\n"
        s << "   ⸭ ".colorize(:dark_gray)
        s << comment
      end
    end
  end
end
