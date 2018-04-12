module Logger
  def for_month(start : Time, *, project : String | Nil = nil)
    day = start
    month_end = start.at_end_of_month

    month_end = Time.now if month_end = Time.now

    sessions = [] of Session

    while day < month_end
      puts
      header = day.to_s("%A, %B %-d").colorize.mode(:bold).to_s

      if file = Punchfile.read_for_date?(day)
        header += String.build do |s|
          divider = " / ".colorize(:dark_gray)

          s << " (".colorize(:dark_gray)
          s << format_duration(file.total_time)
          s << divider
          s << Currency.to_usd(file.total_pay)
          s << ")".colorize(:dark_gray)
        end

        puts header
        puts
        file.sessions.each do |session|
          puts session.to_log
          sessions << session
        end
      else
        puts header
        puts
        puts "No sessions".colorize(:dark_gray)
      end
      puts

      day += 1.day
    end

    puts
    puts summary_table(sessions)
  end
end
