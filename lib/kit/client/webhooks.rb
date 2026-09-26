# frozen_string_literal: true

module Kit
  class Client
    module Webhooks
      def webhooks(**params)
        request(:get, "/webhook_endpoints", params: params)
      end

      def webhook(id)
        request(:get, "/webhook_endpoints/#{esc(id)}")
      end

      # The signing secret comes back in plaintext only on this response.
      def create_webhook(url:, events:, **attributes)
        request(:post, "/webhook_endpoints", body: { url: url, events: events, **attributes })
      end

      def update_webhook(id, **attributes)
        request(:put, "/webhook_endpoints/#{esc(id)}", body: attributes)
      end

      def delete_webhook(id)
        request(:delete, "/webhook_endpoints/#{esc(id)}")
      end

      def rotate_webhook_secret(id, force: nil)
        request(:post, "/webhook_endpoints/#{esc(id)}/rotate_secret", body: { force: force }.compact)
      end

      def revoke_previous_webhook_secret(id)
        request(:post, "/webhook_endpoints/#{esc(id)}/revoke_previous_secret")
      end
    end
  end
end
