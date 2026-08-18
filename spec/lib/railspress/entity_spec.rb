# frozen_string_literal: true

require "rails_helper"

RSpec.describe Railspress::Entity do
  # Use the Project model from the dummy app
  let(:model_class) { Project }

  before do
    Railspress.reset_configuration!
  end

  after do
    Railspress.reset_configuration!
  end

  describe "included module" do
    it "adds _railspress_config class attribute" do
      expect(model_class).to respond_to(:_railspress_config)
    end

    it "creates an EntityConfig instance" do
      expect(model_class._railspress_config).to be_a(Railspress::EntityConfig)
    end
  end

  describe ".railspress_fields" do
    it "registers fields in the config" do
      expect(model_class.railspress_config.fields.keys).to include(:title, :client, :featured, :description, :body, :gallery)
    end

    it "stores explicit types" do
      expect(model_class.railspress_config.fields[:body][:type]).to eq(:rich_text)
      expect(model_class.railspress_config.fields[:description][:type]).to eq(:text)
    end

    it "auto-detects types from schema" do
      expect(model_class.railspress_config.fields[:title][:type]).to eq(:string)
      expect(model_class.railspress_config.fields[:featured][:type]).to eq(:boolean)
    end

    it "detects has_many_attached as :attachments type" do
      expect(model_class.railspress_config.fields[:gallery][:type]).to eq(:attachments)
    end
  end

  describe ".railspress_label" do
    it "sets custom label" do
      expect(model_class.railspress_config.label).to eq("Client Projects")
    end
  end

  describe ".rp_page" do
    it "limits the first page to the RailsPress page size" do
      relation = model_class.rp_page(1)

      expect(relation.limit_value).to eq(Railspress::Entity::PER_PAGE)
      expect(relation.offset_value).to eq(0)
    end

    it "offsets subsequent pages" do
      expect(model_class.rp_page(2).offset_value).to eq(Railspress::Entity::PER_PAGE)
    end

    it "clamps invalid page numbers to the first page" do
      expect(model_class.rp_page(0).offset_value).to eq(0)
    end

    it "uses a model-specific page size" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"
        include Railspress::Entity
      end
      test_class.const_set(:PER_PAGE, 7)

      expect(test_class.rp_page(2).limit_value).to eq(7)
      expect(test_class.rp_page(2).offset_value).to eq(7)
    end
  end

  describe ".rp_per_page_count" do
    it "returns the RailsPress default page size" do
      expect(model_class.rp_per_page_count).to eq(Railspress::Entity::PER_PAGE)
    end

    it "returns a model-specific page size" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"
        include Railspress::Entity
      end
      test_class.const_set(:PER_PAGE, 7)

      expect(test_class.rp_per_page_count).to eq(7)
    end
  end

  describe "pagination compatibility methods" do
    before do
      allow(Railspress.deprecator).to receive(:warn)
    end

    it "delegates page to rp_page" do
      expect(model_class.page(2).offset_value).to eq(Railspress::Entity::PER_PAGE)
    end

    it "warns when page is used" do
      model_class.page(1)

      expect(Railspress.deprecator).to have_received(:warn).with(/use rp_page instead/)
    end

    it "delegates per_page_count to rp_per_page_count" do
      expect(model_class.per_page_count).to eq(model_class.rp_per_page_count)
    end

    it "warns when per_page_count is used" do
      model_class.per_page_count

      expect(Railspress.deprecator).to have_received(:warn).with(/use rp_per_page_count instead/)
    end

    it "preserves a page method defined before inclusion" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"

        def self.page(_page_number) = :host_page

        include Railspress::Entity
      end

      expect(test_class.page(1)).to eq(:host_page)
    end

    it "preserves an inherited page method" do
      parent_class = Class.new(ApplicationRecord) do
        def self.page(_page_number) = :inherited_page
      end
      test_class = Class.new(parent_class) do
        self.table_name = "projects"
        include Railspress::Entity
      end

      expect(test_class.page(1)).to eq(:inherited_page)
    end

    it "preserves a per_page_count method defined before inclusion" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"

        def self.per_page_count = 7

        include Railspress::Entity
      end

      expect(test_class.per_page_count).to eq(7)
    end

    it "allows a page method defined after inclusion to replace the fallback" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"
        include Railspress::Entity
      end
      test_class.define_singleton_method(:page) { |_page_number| :host_page }

      expect(test_class.page(1)).to eq(:host_page)
    end
  end

  describe ".railspress_config" do
    it "returns the EntityConfig" do
      expect(model_class.railspress_config).to be_a(Railspress::EntityConfig)
    end
  end

  describe ".railspress_index_columns" do
    it "returns columns the model responds to from default_index_columns" do
      # Project has :title and :created_at, but not :name or :id method that returns something useful
      columns = model_class.railspress_index_columns
      expect(columns).to include(:title)
      expect(columns).to include(:created_at)
    end

    it "uses RAILSPRESS_INDEX_COLUMNS constant if defined" do
      test_class = Class.new(ApplicationRecord) do
        self.table_name = "projects"
        include Railspress::Entity
      end
      test_class.const_set(:RAILSPRESS_INDEX_COLUMNS, [ :client, :featured, :created_at ])

      expect(test_class.railspress_index_columns).to eq([ :client, :featured, :created_at ])
    end

    it "respects global default_index_columns config" do
      original = Railspress.configuration.default_index_columns

      Railspress.configure do |config|
        config.default_index_columns = [ :title, :client, :created_at ]
      end

      # Project has title, client, and created_at
      expect(model_class.railspress_index_columns).to include(:title, :client, :created_at)

      Railspress.configuration.default_index_columns = original
    end
  end
end

RSpec.describe Railspress::EntityConfig do
  let(:model_class) { Project }
  let(:config) { model_class.railspress_config }

  describe "#model_class" do
    it "lazily resolves class from stored name" do
      # Create a fresh config with just the class name
      fresh_config = Railspress::EntityConfig.new("Project")
      expect(fresh_config.model_class).to eq(Project)
    end

    it "returns the correct class each time called" do
      # Ensures we get fresh class reference (important for reloading)
      expect(config.model_class).to eq(Project)
      expect(config.model_class).to eq(Project)
    end
  end

  describe "#route_key" do
    it "returns pluralized model name" do
      expect(config.route_key).to eq("projects")
    end
  end

  describe "#param_key" do
    it "returns underscored model name" do
      expect(config.param_key).to eq("project")
    end
  end

  describe "#singular_label" do
    it "returns singularized label" do
      # Project model has railspress_label "Client Projects" defined
      expect(config.singular_label).to eq("Client Project")
    end
  end

  describe "#fields" do
    it "returns hash of field definitions" do
      expect(config.fields).to be_a(Hash)
      expect(config.fields[:title]).to be_a(Hash)
    end

    it "includes type for each field" do
      config.fields.each do |_name, field|
        expect(field).to have_key(:type)
      end
    end
  end
end

RSpec.describe "Entity Registration" do
  before do
    Railspress.reset_configuration!
  end

  after do
    Railspress.reset_configuration!
  end

  describe "Railspress.register_entity" do
    it "adds entity to registry with class" do
      Railspress.configure do |config|
        config.register_entity Project
      end

      expect(Railspress.registered_entities).to have_key("projects")
    end

    it "adds entity to registry with string" do
      Railspress.configure do |config|
        config.register_entity "Project"
      end

      expect(Railspress.registered_entities).to have_key("projects")
    end

    it "adds entity to registry with symbol" do
      Railspress.configure do |config|
        config.register_entity :project
      end

      expect(Railspress.registered_entities).to have_key("projects")
    end

    it "stores the EntityConfig" do
      Railspress.configure do |config|
        config.register_entity Project
      end

      expect(Railspress.entity_for("projects")).to be_a(Railspress::EntityConfig)
    end

    it "allows custom label override" do
      original_label = Project.railspress_config.label

      Railspress.configure do |config|
        config.register_entity Project, label: "Work Portfolio"
      end

      expect(Railspress.entity_for("projects").label).to eq("Work Portfolio")

      # Restore original label to avoid test pollution
      Project.railspress_config.label = original_label
    end

    it "raises error if model doesn't include Entity on first access" do
      non_entity_class = Class.new(ApplicationRecord) do
        self.table_name = "railspress_categories"
      end
      stub_const("NonEntityModel", non_entity_class)

      # Registration succeeds (deferred)
      Railspress.configure do |config|
        config.register_entity NonEntityModel
      end

      # Error raised on first access
      expect {
        Railspress.registered_entities
      }.to raise_error(ArgumentError, /must include Railspress::Entity/)
    end

    it "raises error for unknown class name on first access" do
      # Registration succeeds (deferred)
      Railspress.configure do |config|
        config.register_entity "NonexistentModel"
      end

      # Error raised on first access
      expect {
        Railspress.registered_entities
      }.to raise_error(NameError)
    end

    it "raises error for invalid identifier type" do
      expect {
        Railspress.configure do |config|
          config.register_entity 123
        end
      }.to raise_error(ArgumentError, /Expected String, Symbol, or Class/)
    end
  end

  describe "Railspress.entity_for" do
    it "returns nil for unregistered entity" do
      expect(Railspress.entity_for("unknown")).to be_nil
    end

    it "returns config for registered entity" do
      Railspress.configure do |config|
        config.register_entity Project
      end

      expect(Railspress.entity_for("projects")).to be_a(Railspress::EntityConfig)
    end
  end

  describe "Railspress.entity_registered?" do
    it "returns false for unregistered entity" do
      expect(Railspress.entity_registered?("unknown")).to be false
    end

    it "returns true for registered entity" do
      Railspress.configure do |config|
        config.register_entity Project
      end

      expect(Railspress.entity_registered?("projects")).to be true
    end
  end
end
