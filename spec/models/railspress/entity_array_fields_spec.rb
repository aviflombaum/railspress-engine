# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Entity array fields" do
  # Use the Project model from the dummy app which has:
  # - railspress_fields :tech_stack, as: :list
  # - railspress_fields :highlights, as: :lines

  describe ":list field (tech_stack)" do
    it "returns empty array instead of nil for new record" do
      project = Project.new(title: "Test")
      expect(project.tech_stack).to eq([])
    end

    it "parses comma-separated input" do
      project = Project.new(title: "Test")
      project.tech_stack_list = "Ruby, Rails, PostgreSQL"
      expect(project.tech_stack).to eq([ "Ruby", "Rails", "PostgreSQL" ])
    end

    it "deduplicates values" do
      project = Project.new(title: "Test")
      project.tech_stack_list = "Ruby, Rails, Ruby"
      expect(project.tech_stack).to eq([ "Ruby", "Rails" ])
    end

    it "strips whitespace and filters blanks" do
      project = Project.new(title: "Test")
      project.tech_stack_list = "  Ruby  ,, Rails ,  "
      expect(project.tech_stack).to eq([ "Ruby", "Rails" ])
    end

    it "serializes array to comma-separated string" do
      project = Project.new(title: "Test", tech_stack: [ "Ruby", "Rails" ])
      expect(project.tech_stack_list).to eq("Ruby, Rails")
    end

    it "handles empty string input" do
      project = Project.new(title: "Test")
      project.tech_stack_list = ""
      expect(project.tech_stack).to eq([])
    end

    it "handles nil input" do
      project = Project.new(title: "Test")
      project.tech_stack_list = nil
      expect(project.tech_stack).to eq([])
    end

    it "persists to database" do
      project = Project.create!(title: "Test", tech_stack: [ "Ruby", "Rails" ])
      project.reload
      expect(project.tech_stack).to eq([ "Ruby", "Rails" ])
    end
  end

  describe ":lines field (highlights)" do
    it "returns empty array instead of nil for new record" do
      project = Project.new(title: "Test")
      expect(project.highlights).to eq([])
    end

    it "parses line-separated input" do
      project = Project.new(title: "Test")
      project.highlights_list = "Line 1\nLine 2\nLine 3"
      expect(project.highlights).to eq([ "Line 1", "Line 2", "Line 3" ])
    end

    it "preserves duplicates (unlike :list)" do
      project = Project.new(title: "Test")
      project.highlights_list = "Same\nSame\nDifferent"
      expect(project.highlights).to eq([ "Same", "Same", "Different" ])
    end

    it "handles CRLF line endings" do
      project = Project.new(title: "Test")
      project.highlights_list = "Line 1\r\nLine 2"
      expect(project.highlights).to eq([ "Line 1", "Line 2" ])
    end

    it "strips whitespace and filters blanks" do
      project = Project.new(title: "Test")
      project.highlights_list = "  Line 1  \n\n  Line 2  \n"
      expect(project.highlights).to eq([ "Line 1", "Line 2" ])
    end

    it "serializes array to newline-separated string" do
      project = Project.new(title: "Test", highlights: [ "Line 1", "Line 2" ])
      expect(project.highlights_list).to eq("Line 1\nLine 2")
    end

    it "handles empty string input" do
      project = Project.new(title: "Test")
      project.highlights_list = ""
      expect(project.highlights).to eq([])
    end

    it "persists to database" do
      project = Project.create!(title: "Test", highlights: [ "Fact 1", "Fact 2" ])
      project.reload
      expect(project.highlights).to eq([ "Fact 1", "Fact 2" ])
    end
  end

  describe "round-trip editing" do
    it "preserves values through edit cycle for :list" do
      project = Project.create!(title: "Test")
      project.tech_stack_list = "Ruby, Rails, PostgreSQL"
      project.save!
      project.reload

      # Simulate form re-population
      expect(project.tech_stack_list).to eq("Ruby, Rails, PostgreSQL")

      # Edit again
      project.tech_stack_list = project.tech_stack_list + ", Redis"
      project.save!
      project.reload
      expect(project.tech_stack).to eq([ "Ruby", "Rails", "PostgreSQL", "Redis" ])
    end

    it "preserves values through edit cycle for :lines" do
      project = Project.create!(title: "Test")
      project.highlights_list = "Fact 1\nFact 2"
      project.save!
      project.reload

      # Simulate form re-population
      expect(project.highlights_list).to eq("Fact 1\nFact 2")

      # Edit again
      project.highlights_list = project.highlights_list + "\nFact 3"
      project.save!
      project.reload
      expect(project.highlights).to eq([ "Fact 1", "Fact 2", "Fact 3" ])
    end
  end

  describe "EntityConfig field detection" do
    it "registers :list type in entity config" do
      config = Project.railspress_config
      expect(config.fields[:tech_stack][:type]).to eq(:list)
    end

    it "registers :lines type in entity config" do
      config = Project.railspress_config
      expect(config.fields[:highlights][:type]).to eq(:lines)
    end
  end
end
