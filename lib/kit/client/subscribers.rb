# frozen_string_literal: true

module Kit
  class Client
    module Subscribers
      # Filters: email_address (exact), status, created_after/before,
      # updated_after/before, sort_field, sort_order, include, slim.
      def subscribers(**params)
        request(:get, "/subscribers", params: params)
      end

      def subscriber(id)
        request(:get, "/subscribers/#{id}")
      end

      # Upserts: an existing email_address gets its first_name updated.
      def create_subscriber(email_address:, **attributes)
        request(:post, "/subscribers", body: { email_address: email_address, **attributes })
      end

      def update_subscriber(id, **attributes)
        request(:put, "/subscribers/#{id}", body: attributes)
      end

      def unsubscribe_subscriber(id)
        request(:post, "/subscribers/#{id}/unsubscribe")
      end

      def bulk_create_subscribers(subscribers, callback_url: nil)
        request(:post, "/bulk/subscribers", body: { subscribers: subscribers, callback_url: callback_url }.compact)
      end

      def subscriber_stats(id, **params)
        request(:get, "/subscribers/#{id}/stats", params: params)
      end

      def subscriber_tags(id, **params)
        request(:get, "/subscribers/#{id}/tags", params: params)
      end

      def pin_subscriber_location(id, **location)
        request(:post, "/subscribers/#{id}/location", body: { location: location })
      end

      def update_subscriber_location(id, **location)
        request(:patch, "/subscribers/#{id}/location", body: { location: location })
      end

      def delete_subscriber_location(id)
        request(:delete, "/subscribers/#{id}/location")
      end
    end
  end
end
