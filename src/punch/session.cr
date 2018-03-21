class Session
  property punchfile : Punchfile?
  
  JSON.mapping({
    project: String,
    in: { type: Time, converter: Time::EpochMillisConverter, getter: false },
    out: { type: Time, nilable: true, converter: Time::EpochMillisConverter, getter: false },
    rewind: Int64,
    # Have to account for the old single-comment format
    comments: { type: Array(String), setter: false },
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
    if project = config.projects[@project]?
      if project.hourlyRate
        duration.total_hours * project.hourlyRate
      else 
        0.0
      end
    else
      0.0
    end
  end

  def punched_in?
    !@time_out
  end
end