class Session
  property punchfile : Punchfile?

  TIME_FORMAT = "%l:%M%p"

  JSON.mapping({
    project:  String,
    in:       {type: Time, converter: Time::EpochMillisConverter, getter: false},
    out:      {type: Time, nilable: true, converter: Time::EpochMillisConverter, getter: false},
    rewind:   Int64,
    comments: {type: Array(String), setter: false},
  })

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

  def add_comment(comment : String)
    @comments << comment
  end

  def duration
    (@out || Time.now) - @in
  end

  def pay : Float64
    config = Config.instance
    if (project = config.projects[@project]?) && project.hourly_rate
      duration.total_hours * project.hourly_rate
    else
      0.0
    end
  end

  def punched_in?
    !@out
  end

  def to_log
    String.build do |s|
      time_in = in.to_s(TIME_FORMAT)

      if punched_in?
        time_out = "NOW".ljust(time_in.size).colorize(:green)
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
