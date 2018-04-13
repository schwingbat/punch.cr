require "./spec_helper"

describe Config do
  describe "load" do
    it "loads file from a given path" do
      config = Config.load(TEST_CONFIG_PATH)

      config.user.name.should eq "Test Person"
      config.clients.size.should eq 1
    end
  end

  describe "punch_path" do
    it "returns absolute path to punchfile folder" do
      config = Config.load(TEST_CONFIG_PATH)
      expected_path = File.join File.dirname(TEST_CONFIG_PATH), "punches"

      config.punch_path.should eq expected_path
    end
  end
end