# frozen_string_literal: true

module Kit
  class Client
    module Tags
      def tags(**params)
        request(:get, "/tags", params: params)
      end

      def create_tag(name)
        request(:post, "/tags", body: { name: name })
      end

      def update_tag(id, name:)
        request(:put, "/tags/#{id}", body: { name: name })
      end

      def tag_subscribers(id, **params)
        request(:get, "/tags/#{id}/subscribers", params: params)
      end

      def tag_subscriber(tag_id, email_address: nil, subscriber_id: nil)
        if subscriber_id
          request(:post, "/tags/#{tag_id}/subscribers/#{subscriber_id}")
        else
          request(:post, "/tags/#{tag_id}/subscribers", body: { email_address: email_address })
        end
      end

      def untag_subscriber(tag_id, email_address: nil, subscriber_id: nil)
        if subscriber_id
          request(:delete, "/tags/#{tag_id}/subscribers/#{subscriber_id}")
        else
          request(:delete, "/tags/#{tag_id}/subscribers", params: { email_address: email_address })
        end
      end

      # Bulk endpoints need OAuth; taggings are { tag_id:, subscriber_id: } pairs.
      def bulk_create_tags(tags, callback_url: nil)
        request(:post, "/bulk/tags", body: { tags: tags, callback_url: callback_url }.compact)
      end

      def bulk_delete_tags(tags, callback_url: nil)
        request(:delete, "/bulk/tags", body: { tags: tags, callback_url: callback_url }.compact)
      end

      def bulk_tag_subscribers(taggings, callback_url: nil)
        request(:post, "/bulk/tags/subscribers", body: { taggings: taggings, callback_url: callback_url }.compact)
      end

      def bulk_untag_subscribers(taggings, callback_url: nil)
        request(:delete, "/bulk/tags/subscribers", body: { taggings: taggings, callback_url: callback_url }.compact)
      end
    end
  end
end
