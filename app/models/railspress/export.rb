module Railspress
  class Export < ApplicationRecord
    STATUSES = %w[pending processing completed failed].freeze
    EXPORT_TYPES = %w[posts].freeze

    has_one_attached :file

    validates :export_type, presence: true, inclusion: { in: EXPORT_TYPES }
    validates :status, presence: true, inclusion: { in: STATUSES }

    scope :by_type, ->(type) { where(export_type: type) }
    scope :recent, -> { order(created_at: :desc).limit(10) }
    scope :pending, -> { where(status: "pending") }
    scope :processing, -> { where(status: "processing") }
    scope :completed, -> { where(status: "completed") }
    scope :failed, -> { where(status: "failed") }

    def pending?
      status == "pending"
    end

    def processing?
      status == "processing"
    end

    def completed?
      status == "completed"
    end

    def failed?
      status == "failed"
    end

    def mark_processing!
      update!(status: "processing")
    end

    def mark_completed!
      update!(status: "completed")
    end

    def mark_failed!
      update!(status: "failed")
    end

    def add_error(message)
      errors_array = parsed_errors
      errors_array << message
      update!(error_messages: errors_array.to_json, error_count: errors_array.size)
    end

    def increment_success!
      increment!(:success_count)
    end

    def increment_total!
      increment!(:total_count)
    end

    def parsed_errors
      return [] if error_messages.blank?
      JSON.parse(error_messages)
    rescue JSON::ParserError
      []
    end
  end
end
