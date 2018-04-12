require "./log_day"
require "./log_week"
require "./log_month"
require "./log_year"

class PunchLogger
  include Logger

  def summary_table(sessions : Array(Session))
    project_data = Config.instance.projects

    total_time = Time::Span.new(nanoseconds: 0)
    total_pay = 0
    total_punches = 0

    time_by_project = {} of String => Time::Span
    pay_by_project = Hash(String, Float64).new(0.0)
    punches_by_project = Hash(String, Int32).new(0)

    # Tally up session numbers
    sessions.each do |session|
      time = (session.out || Time.new) - session.in
      pay = if project = project_data[session.project]?
              project.hourly_rate * time.total_hours
            else
              0
            end

      total_time += time
      total_pay += pay
      total_punches += 1

      time_by_project[session.project] = Time::Span.new(nanoseconds: 0) if !time_by_project[session.project]?
      pay_by_project[session.project] = 0.0 if !pay_by_project[session.project]?
      punches_by_project[session.project] = 0 if !punches_by_project[session.project]?

      time_by_project[session.project] += time
      pay_by_project[session.project] += pay
      punches_by_project[session.project] += 1
    end

    # Build table sorted by time spend descending
    projects = sessions
      .map { |s| s.project }
      .uniq
      .sort_by { |p| time_by_project[p] }
      .reverse

    columns = [
      [] of String, # Name
      [] of String, # Time
      [] of String, # Pay
      [] of String, # Punches
    ]
    rows = [] of String
    col_sizes = [] of Int32

    projects.each do |project|
      name = if project_data[project]?
               project_data[project].name
             else
               project
             end
      time = time_by_project[project]
      pay = pay_by_project[project]
      punches = punches_by_project[project]

      columns[0] << name
      columns[1] << format_duration(time, tablified: true)
      columns[2] << Currency.to_usd(pay)
      columns[3] << punches.to_s + " punch#{"es" if punches != 1}"
    end

    columns.each do |row|
      # Get the length of the longest item in the column
      min = (row.map &.size).reduce { |max, c| Math.max max, c }
      col_sizes << min

      row.each_with_index do |r, i|
        if rows[i]?
          rows[i] += "   " + r.rjust(min)
        else
          rows << r.ljust(min).colorize(:yellow).to_s
        end
      end
    end

    puts rows.join "\n"
    puts "\n"

    totals = String.build do |s|
      divider = " / ".colorize(:dark_gray)

      s << "TOTAL".rjust(col_sizes[0]).colorize(:cyan)
      s << "  (".colorize(:dark_gray)
      s << format_duration(total_time, tablified: true).ljust(col_sizes[1])
      s << divider
      s << Currency.to_usd(total_pay).ljust(col_sizes[2])
      s << divider
      s << "#{total_punches} punch#{"es" if total_punches != 1}".ljust(col_sizes[3])
      s << ")".colorize(:dark_gray)
    end

    puts totals
  end
end
