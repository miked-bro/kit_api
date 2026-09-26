# frozen_string_literal: true

module Kit
  class Client
    module CustomFields
      def custom_fields(**params)
        request(:get, "/custom_fields", params: params)
      end

      def create_custom_field(label:)
        request(:post, "/custom_fields", body: { label: label })
      end

      def update_custom_field(id, label:)
        request(:put, "/custom_fields/#{id}", body: { label: label })
      end

      def delete_custom_field(id)
        request(:delete, "/custom_fields/#{id}")
      end

      def bulk_create_custom_fields(custom_fields, callback_url: nil)
        request(:post, "/bulk/custom_fields",
          body: { custom_fields: custom_fields, callback_url: callback_url }.compact)
      end

      # Values are { subscriber_id:, subscriber_custom_field_id:, value: } triples.
      def bulk_update_subscriber_fields(custom_field_values, callback_url: nil)
        request(:post, "/bulk/custom_fields/subscribers",
          body: { custom_field_values: custom_field_values, callback_url: callback_url }.compact)
      end
    end
  end
end
