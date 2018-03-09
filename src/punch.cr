require "./punch/*"
require "./punch/config/config"
require "colorize"

module Punch
  class App
    extend CLI
    include CLI

    config = Config.new

    @@commands = [] of CLI::Command

    punch "in <project>", purpose: "begin tracking time on a project" do |args|
      project = args["project"]

      puts "punching in on project: #{project}"
    end

    punch "out [comment*]", purpose: "stop tracking time on the current project" do |args|
      str = "punching out"
      str += " with comment: \"#{args["comment"]}\"" if args["comment"]?
      puts str
    end

    punch "project <name>", purpose: "show a summary of stats for a project" do |args|
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

    punch "projects [names...]", purpose: "show summaries for multiple projects" do |args|
      
    end
  end
end

app = Punch::App.new
app.run