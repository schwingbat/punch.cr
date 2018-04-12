module Logger
  def for_day(start : Time, *, project : String | Nil = nil)
    if file = Punchfile.read_for_date?(start)
      if project
        sessions = file.sessions.select { |s| s.project == project }
      else
        sessions = file.sessions
      end

      puts "\n"
      sessions.each do |session|
        puts session.to_log
      end
      puts "\n"

      puts start.to_s("")
      puts summary_table(sessions)
    else
      message = "No sessions for #{start.to_s("%A, %B %-d")}"
      message += " #{start.to_s("%Y")}" if start.year != Time.new.year

      puts message
    end
  end
end
