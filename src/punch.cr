require "./punch/*"
require "./punch/config/config"
require "colorize"

module Punch
  class App
    extend CLI
    include CLI

    config = Config.new

    @@commands = [] of CLI::Command

    # TODO: Convert CLI to work with this nested block syntax.
    #       It makes it easier to add more options and configuration stuff later
    #       since trying to fit it all one one line can get a bit difficult.

    punch "in <project>" do |cmd|
      cmd.purpose "Start tracking time on a project."
      cmd.argument "project", description: "Name of the project to punch in on."

      cmd.run do |args|
        # TODO: Implement punch in
        puts "Not implemented yet"
      end
    end

    punch "out [*comment]" do |cmd|
      cmd.purpose "Stop tracking time on a project (and add an optional comment)"
      cmd.argument "comment", description: "A description of how you spent your time."

      cmd.run do |args|
        # TODO: Implement punch out
        puts "Not implemented yet"
      end
    end
    
    punch "comment <*comment>" do |cmd|
      cmd.purpose "Add a comment to your current session, or to your previous session if punched out."
      cmd.argument "comment", description: "A description of how you spent your time."
      
      cmd.run do |args|
        # TODO: Implement comment command
        puts "Not implemented yet"
      end
    end
    
    punch "create <project> <time_in> <time_out> [*comment]" do |cmd|
      cmd.purpose "Create a punch with a start and end."
      
      cmd.argument "project", description: "The project being worked on during this session."
      cmd.argument "time_in", description: "Time the session started (in the format MM/DD/YYYY@HH:MM)."
      cmd.argument "time_out", description: "Time the session ended (in the format MM/DD/YYYY@HH:MM)."
      cmd.argument "comment", description: "A description of how you spent your time."
      
      cmd.run do |args|
        # TODO: Implement punch creation
        puts "Not implemented yet"
      end
    end
    
    punch "now" do |cmd|
      cmd.purpose "Show the status of the current session."
      
      cmd.run do |args|
        # TODO: Implement `now`
        puts "Not implemented yet"
      end
    end
    
    punch "watch" do |cmd|
      cmd.purpose "Continue running to show the status of your current punch in real time."
      
      cmd.run do |args|
        # TODO: Implement watch
        puts "Not implemented yet"
      end
    end

    punch "project <name>" do |cmd|
      cmd.purpose "Show a summary of stats for a project."
      cmd.argument "name", description: "The name of the project to summarize."
      
      cmd.run do |args|
        project = args["name"]
        project_info = config.projects[project]?
        name = project_info ? project_info.name : project
        punches = Punchfile.all_punches.select do |punch|
          punch.project === project
        end

        total_hours = (punches.sum &.duration.total_hours).round(2)
        total_pay = (punches.sum &.pay).round(2)

        puts "You have worked on #{name} for a total of #{total_hours} hours and earned $#{total_pay} over #{punches.size} punches."
      end
    end

    punch "projects [names...]" do |cmd|
      cmd.purpose "Show summaries for multiple projects."
      cmd.argument "names", description: "A space-separated list of projects to summarize."
      
      cmd.run do |args|
        # TODO: Implement `invoke` so I can alias this to several calls of `project <name>`
        puts "Not implemented yet."
      end
    end
    
    punch "log [*when]" do |cmd|
      cmd.purpose "Show a summary of punches for a given period."
      cmd.argument "when", description: "The time period to generate a log for (try `today`, `yesterday`, `this month`, `last month`)"
      
      cmd.run do |args|
        # TODO: Implement log
        puts "Not implemented yet"
      end
    end
    
    punch "invoice <project> <start_date> <end_date> <output_file>" do |cmd|
      cmd.purpose "Automatically generate an invoice using punch data."
      
      cmd.argument "project", description: "The project for which you'd like to invoice"
      cmd.argument "start_date", description: "The start of the invoice period (in the format MM/DD/YYYY)."
      cmd.argument "end_date", description: "The end of the invoice period (in the format MM/DD/YYYY)."
      cmd.argument "output_file", description: "The path for the resulting invoice file, e.g. ~/invoices/project_mar_2018.pdf"
      
      cmd.run do |args|
        # TODO: Implement invoicing
        puts "Not implemented yet"
      end
    end
    
    punch "sync" do |cmd|
      cmd.purpose "Synchronize with any providers in your config file."
      
      cmd.run do |args|
        # TODO: Implement sync
        puts "Not implemented yet"
      end
    end
    
    punch "config [editor]" do |cmd|
      cmd.purpose "Open the config file in a text editor - uses EDITOR env var unless an editor is specified."
      cmd.argument "editor", description: "Name of or path to the editor you'd like to use."
      
      cmd.run do |args|
        # TODO: Implement config editing
        puts "Not implemented yet"
      end
    end
    
    punch "edit <date> [editor]" do |cmd|
      cmd.purpose "Edit punchfile for the given date - uses EDITOR env var unless an editor is specified."
      
      cmd.argument "date", description: "Date of the punchfile you'd like to edit (in the format DD/MM/YYYY)."
      cmd.argument "editor", description: "Name of or path to the editor you'd like to use."
      
      cmd.run do |args|
        # TODO: Implement punchfile editing
        puts "Not implemented yet"
      end
    end
    
    punch "timestamp <time>" do |cmd|
      cmd.purpose "Get a millisecond timestamp for a given time"
      cmd.argument "time", description: "The date and time you'd like a timestamp for (in the format MM/DD/YYYY@HH:MM)"
      
      cmd.run do |args|
        # TODO: Implement timestamp
        puts "Not implemented yet"
      end
    end
  end
end

app = Punch::App.new
app.run