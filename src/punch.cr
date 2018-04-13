require "./punch/*"
require "./punch/log/log"
require "./server/server"
require "colorize"
require "option_parser"

module Punch
  class App
    include CLI

    DATETIME_FORMAT_STRING = "MM/DD/YYYY@HH:MM(AM/PM)"
    DATETIME_FORMAT        = "%-m/%-d/%Y@%I:%M%p"
    DATE_FORMAT_STRING     = "MM/DD/YYYY"
    DATE_FORMAT            = "%-m/%-d/%Y"
    TIME_FORMAT            = "%I:%M%p"

    @@commands = [] of CLI::Command

    def current_session
      # A current session can only be in the latest file.
      # Sort in calendar order to make sure we're checking
      # the last one.

      files = Dir.children(@config.punch_path)
        .select { |f| File.extname(f) == ".json" }
        .sort_by do |f|
          f.split(/[_\.]/)[1..3].map &.to_i32
        end

      path = File.join(@config.punch_path, files.last)
      punchfile = Punchfile.from_json(File.read(path))

      punchfile.sessions.find &.out.nil?
    end

    def most_recent_session
      latest_file = Dir.children(@config.punch_path)
        .select { |f| File.extname(f) == ".json" }
        .sort_by { |f| f.split(/[_\.]/)[1..3].map &.to_i32 }
        .last

      path = File.join(@config.punch_path, latest_file)
      punchfile = Punchfile.from_json(File.read(path))

      punchfile.sessions.last
    end

    def label_for(project : String)
      if conf = @config.projects[project]?
        conf.name
      else
        project
      end
    end

    def rate_for(project : String)
      if conf = @config.projects[project]?
        if conf.hourly_rate
          return conf.hourly_rate
        end
      end
      return 0.0
    end

    def number_from_string(number : String)
      if num = number.to_i32?
        return num
      end

      numbers = [ "zero", "one", "two", "three", "four", "five",
                  "six", "seven", "eight", "nine", "ten", "eleven",
                  "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
                  "seventeen", "eighteen", "nineteen", "twenty" ]

      index = -1
      numbers.each_with_index do |num, i|
        if num == number
          index = i
          break
        end
      end

      index
    end

    def initialize
      @config = Config.load("#{ENV["HOME"]}/.punch/punchconfig.json")

      punch "in <project>" do |cmd|
        cmd.purpose "Start tracking time on a project."
        cmd.argument "project", description: "Name of the project to punch in on (#{@config.projects.keys[0..2].join(", ")}, etc)."

        cmd.run do |args|
          if current = current_session
            puts "You're already punched in on #{label_for current.project}! Punch out first."
          else
            project = args["project"].as(String)

            file = Punchfile.read_or_create_for_time(Time.now)
            file.punch_in project, autosave: true

            puts "Punched in on #{label_for project} at #{Time.now.to_s(TIME_FORMAT)}."
          end
        end
      end

      punch "out [*comment]" do |cmd|
        cmd.purpose "Stop tracking time on a project (and add an optional comment)"
        cmd.argument "comment", description: "A description of how you spent your time."

        cmd.run do |args|
          session = current_session

          if !session
            next puts "You're not punched in."
          end

          if args["comment"]?
            session.add_comment args["comment"].as(String)
          end

          session.punch_out
          session.save

          puts "Punched out of #{label_for session.project} at #{Time.now.to_s(TIME_FORMAT)}."
        end
      end

      punch "comment <*comment>" do |cmd|
        cmd.purpose "Add a comment to your current session, or to your previous session if punched out."
        cmd.argument "comment", description: "A description of how you spent your time."

        cmd.run do |args|
          if current = current_session
            current.add_comment args["comment"].as(String)
            puts
            puts "Comment Added".colorize.mode :bold
            puts
            puts current.to_log
            current.save
          elsif recent = most_recent_session
            print "You're not currently punched in. Add comment to latest session (#{label_for recent.project} >> #{recent.in.to_s(TIME_FORMAT)} - #{recent.out.as(Time).to_s(TIME_FORMAT)}) instead? [y/n] "
            response = gets.as(String).chomp.downcase

            if response == "y"
              recent.add_comment args["comment"].as(String)
              puts
              puts "Comment Added".colorize.mode :bold
              puts
              puts recent.to_log
              recent.save
            end
          end
        end
      end

      punch "create <project> <time_in> <time_out> [*comment]" do |cmd|
        cmd.purpose "Create a punch with a start and end."

        cmd.argument "project", description: "The project being worked on during this session."
        cmd.argument "time_in", description: "Time the session started (in the format #{DATETIME_FORMAT_STRING})."
        cmd.argument "time_out", description: "Time the session ended (in the format #{DATETIME_FORMAT_STRING})."
        cmd.argument "comment", description: "A description of how you spent your time."

        cmd.run do |args|
          # TODO: Implement punch creation
          puts "punch create: Not implemented yet"
        end
      end

      punch "now" do |cmd|
        cmd.purpose "Show the status of the current session."

        cmd.run do |args|
          if session = current_session
            project = session.project
            time = session.in.to_s("%I:%M %P")

            if time[0] == '0'
              time = time[1...time.size]
            end

            rate = rate_for(project)
            duration = format_duration(Time.now - session.in)

            str = "You've been working on #{label_for(project)} since #{time} (#{duration} ago)"

            if rate && rate != 0.0
              pay = session.duration.total_hours * rate
              str += " and earned $#{pay.round(2)}"
            end

            puts str += "."
          else
            puts "You're not punched in right now."
          end
        end
      end

      punch "watch" do |cmd|
        cmd.purpose "Continue running to show the status of your current punch in real time."

        cmd.run do |args|
          # TODO: Implement watch
          puts "punch watch: Not implemented yet"
        end
      end

      punch "project <name>" do |cmd|
        cmd.purpose "Show a summary of stats for a project."
        cmd.argument "name", description: "The name of the project to summarize."

        cmd.run do |args|
          project = args["name"]
          project_info = @config.projects[project]?
          name = project_info ? project_info.name : project
          punches = Punchfile.all_sessions.select do |punch|
            punch.project === project
          end

          total_hours = format_duration(punches.sum &.duration)
          total_pay = Currency.to_usd(punches.sum &.pay)

          puts "You have worked on #{name} for a total of #{total_hours} and earned #{total_pay} over #{punches.size} punch#{"es" if punches.size != 1}."
        end
      end

      punch "projects [names...]" do |cmd|
        cmd.purpose "Show summaries for multiple projects."
        cmd.argument "names", description: "A space-separated list of projects to summarize."

        cmd.run do |args|
          # TODO: Implement `invoke` so I can alias this to several calls of `project <name>`
          puts "punch projects: Not implemented yet."
        end
      end

      punch "log [*when]" do |cmd|
        cmd.purpose "Show a summary of punches for a given period."
        cmd.argument "when", description: "The time period to generate a log for (try `today`, `yesterday`, `this month`, `last month`)"
        # cmd.flag ["--project", "-p"], description: "Show only sessions that match a given project name"

        cmd.run do |args|
          if args["when"]?
            time = args["when"].as(String).strip.downcase
          else
            time = "now"
          end

          log = PunchLogger.new

          next log.for_day(Time.now.at_beginning_of_day) if ["today", "now"].includes? time
          next log.for_day(Time.now.at_beginning_of_day - 1.day) if time == "yesterday"

          modifier = 0

          # Check for last __, next __, this __
          if /^last\s/.match(time)
            modifier = -1
            time = time.split(" ")[1...time.size].join(" ").strip
          elsif /^next\s/.match(time)
            modifier = +1
            time = time.split(" ")[1...time.size].join(" ").strip
          elsif /^this\s/.match(time)
            time = time.split(" ")[1...time.size].join(" ").strip

            # Then check for relative times: "two days ago", etc.
          elsif matched = /^(.+) (.+) ago$/.match(time)
            number_string = matched[1]
            number = number_from_string(number_string)
            unit = matched[2]

            modifier = -number
            time = unit
          end

          if modifier > 0
            next puts "You can't view a log for punches that haven't happened yet."
          end

          case time
          when "day", "days"
            log.for_day(Time.now.at_beginning_of_day + modifier.days)
          when "week", "weeks"
            log.for_week(Time.now.at_beginning_of_week + modifier.weeks)
          when "month", "months"
            log.for_month(Time.now.at_beginning_of_month + modifier.months)
          when "year", "years"
            log.for_year(Time.now.at_beginning_of_year + modifier.years)
          when "monday", "mondays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.monday? || counter != modifier
              counter -= 1 if day.monday?
              day -= 1.day
            end

            log.for_day(day)
          when "tuesday", "tuesdays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.tuesday? || counter != modifier
              counter -= 1 if day.tuesday?
              day -= 1.day
            end

            log.for_day(day)
          when "wednesday", "wednesdays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.wednesday? || counter != modifier
              counter -= 1 if day.wednesday?
              day -= 1.day
            end

            log.for_day(day)
          when "thursday", "thursdays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.thursday? || counter != modifier
              counter -= 1 if day.thursday?
              day -= 1.day
            end

            log.for_day(day)
          when "friday", "fridays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.friday? || counter != modifier
              counter -= 1 if day.friday?
              day -= 1.day
            end

            log.for_day(day)
          when "saturday", "saturdays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.saturday? || counter != modifier
              counter -= 1 if day.saturday?
              day -= 1.day
            end

            log.for_day(day)
          when "sunday", "sundays"
            day = Time.now.at_beginning_of_day
            counter = -1
            if modifier == 0
              counter = 0
            end

            while !day.sunday? || counter != modifier
              counter -= 1 if day.sunday?
              day -= 1.day
            end

            log.for_day(day)
          when "january", "february", "march", "april",
               "may", "june", "july", "august",
               "september", "october", "november", "december"
            puts "You chose a month"
          else
            puts "Sorry, I'm not sure when you mean."
          end
        end
      end

      punch "invoice <project> <start_date> <end_date> <output_file>" do |cmd|
        cmd.purpose "Automatically generate an invoice using punch data."

        cmd.argument "project", description: "The project you want to invoice for."
        cmd.argument "start_date", description: "Start of the invoice period (in the format #{DATE_FORMAT_STRING})."
        cmd.argument "end_date", description: "End of the invoice period (in the format #{DATE_FORMAT_STRING})."
        cmd.argument "output_file", description: "Path to save the invoice to (e.g. ~/invoices/project_mar_2018.pdf)."

        cmd.run do |args|
          # TODO: Implement invoicing
          puts "punch invoice: Not implemented yet"
        end
      end

      punch "sync" do |cmd|
        cmd.purpose "Synchronize with any providers in your config file."

        cmd.run do |args|
          # TODO: Implement sync
          puts "punch sync: Not implemented yet"
        end
      end

      punch "config [editor]" do |cmd|
        cmd.purpose "Open the config file in a text editor - uses EDITOR env var unless an editor is specified."
        cmd.argument "editor", description: "Name of or path to the editor you'd like to use."

        cmd.run do |args|
          config_path = "#{ENV["HOME"]}/.punch/punchconfig.json"

          if args["editor"]?
            system "#{args["editor"].as(String)} #{config_path}"
          else
            system "$EDITOR #{config_path}"
          end
        end
      end

      punch "edit <date> [editor]" do |cmd|
        cmd.purpose "Edit punchfile for the given date - uses EDITOR env var unless an editor is specified."

        cmd.argument "date", description: "Date of the punchfile you'd like to edit (in the format #{DATE_FORMAT_STRING})."
        cmd.argument "editor", description: "Name of or path to the editor you'd like to use."

        cmd.run do |args|
          # TODO: Implement punchfile editing
          puts "punch edit: Not implemented yet"
        end
      end

      punch "timestamp <time>" do |cmd|
        cmd.purpose "Get a millisecond timestamp for a given time"
        cmd.argument "time", description: "The date and time you'd like a timestamp for (in the format #{DATETIME_FORMAT_STRING})"

        cmd.run do |args|
          time = Time.parse(args["time"].as(String).downcase, DATETIME_FORMAT)
          puts time.epoch_ms
        end
      end

      punch "server [port]" do |cmd|
        cmd.purpose "Start up the punch web server to interact with punch through a web-based GUI"
        cmd.argument "port", description: "The port for the web server. Defaults to 5555."

        cmd.run do |args|
          if args["port"]?
            port = args["port"].as(String).to_i
          else
            port = 5555
          end

          Server.start(port)
        end
      end
    end
  end
end

app = Punch::App.new
app.run
