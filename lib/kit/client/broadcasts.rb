# frozen_string_literal: true

module Kit
  class Client
    module Broadcasts
      def broadcasts(**params)
        request(:get, "/broadcasts", params: params)
      end

      def broadcast(id)
        request(:get, "/broadcasts/#{id}")
      end

      # send_at: nil leaves it a draft; subscriber_filter targets tags/segments.
      def create_broadcast(**attributes)
        request(:post, "/broadcasts", body: attributes)
      end

      def update_broadcast(id, **attributes)
        request(:put, "/broadcasts/#{id}", body: attributes)
      end

      def delete_broadcast(id)
        request(:delete, "/broadcasts/#{id}")
      end

      def broadcast_stats(id)
        request(:get, "/broadcasts/#{id}/stats")
      end

      # Filters: sent_after/before, status.
      def broadcasts_stats(**params)
        request(:get, "/broadcasts/stats", params: params)
      end

      def broadcast_clicks(id, **params)
        request(:get, "/broadcasts/#{id}/clicks", params: params)
      end
    end
  end
end
