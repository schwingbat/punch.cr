require "./spec_helper"

describe Punchfile do
  Spec.before_each do
    config = Config.instance
    Dir.children(config.punch_path).each do |f|
      File.delete File.join(config.punch_path, f)
    end
  end

  describe "#initialize" do
    it "creates a fresh punchfile in memory with no sessions" do
      file = Punchfile.new
      file.sessions.size.should eq 0
    end
  end

  describe "#punch_in" do
    it "creates a new session for a given project" do
      file = Punchfile.new
      file.punch_in "evil-app"

      file.sessions.size.should eq 1
      file.sessions[0].project.should eq "evil-app"
    end

    it "saves file if autosave is set to true" do
      file = Punchfile.new(Time.new(year: 2017, month: 9, day: 1))
      file.punch_in "testing", autosave: true

      File.exists?(file.file_path).should eq true
    end
  end

  describe "#punch_out" do
    it "punches out of the most recent matching session" do
      file = Punchfile.new
      file.punch_in "evil-app"
      file.punch_out "evil-app"

      file.sessions.size.should eq 1
      file.sessions[0].out.should_not eq nil
    end

    it "saves file if autosave is set to true" do
      file = Punchfile.new(Time.new(year: 2013, month: 4, day: 22))
      file.punch_in "testing"
      file.punch_out "testing", autosave: true

      File.exists?(file.file_path).should eq true
    end
  end

  describe "#create" do
    it "creates a punchfile for a given date" do
      file = Punchfile.new(Time.new(year: 2018, month: 6, day: 19))
      File.basename(file.file_path).should eq "punch_2018_6_19.json"
    end
  end

  describe "#save" do
    it "saves punchfile to disk" do
      file = Punchfile.new(Time.new(year: 2018, month: 6, day: 19))
      file.punch_in "evil-app"
      file.punch_out "evil-app"

      file.save

      File.exists?(file.file_path).should be_true
    end
  end

  describe "#read_or_create_for_time" do
    it "creates a fresh punchfile if one doesn't exist for the day" do
      time = Time.new(year: 2018, month: 9, day: 5)
      file = Punchfile.read_or_create_for_time(time)

      file.sessions.size.should eq 0
    end

    it "reads existing punchfile from disk if it exists" do
      time = Time.new(year: 2016, month: 4, day: 10)
      orig_file = Punchfile.read_or_create_for_time(time)
      orig_file.punch_in "test"
      orig_file.punch_out "test"
      orig_file.save

      File.exists?(orig_file.file_path).should be_true

      new_file = Punchfile.read_or_create_for_time(time)

      new_file.sessions.size.should eq 1
    end
  end
end