module Railspress
  module Admin
    class PrototypesController < BaseController
      # Prototype views for iterating on UI/UX
      # Access at: /admin/prototypes/:name
      #
      # These views use real CSS and Stimulus controllers
      # but work with mock data for fast iteration.

      def image_section
        # Mock data for prototyping
        @mock_image_url = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1200&q=80"
        @mock_filename = "mountain-landscape.jpg"
        @mock_filesize = "1.2 MB"
        @mock_focal_point = { x: 0.35, y: 0.45 }
        @contexts = Railspress.image_contexts.presence || default_contexts
      end

      private

      def default_contexts
        {
          hero: { aspect: [21, 9] },
          card: { aspect: [16, 10] },
          tall: { aspect: [4, 5] }
        }
      end
    end
  end
end
