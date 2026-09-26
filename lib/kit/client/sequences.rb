# frozen_string_literal: true

module Kit
  class Client
    module Sequences
      def sequences(**params)
        request(:get, "/sequences", params: params)
      end

      def sequence(id)
        request(:get, "/sequences/#{esc(id)}")
      end

      def create_sequence(name:, **attributes)
        request(:post, "/sequences", body: { name: name, **attributes })
      end

      def update_sequence(id, **attributes)
        request(:put, "/sequences/#{esc(id)}", body: attributes)
      end

      def delete_sequence(id)
        request(:delete, "/sequences/#{esc(id)}")
      end

      def sequence_subscribers(id, **params)
        request(:get, "/sequences/#{esc(id)}/subscribers", params: params)
      end

      def add_subscriber_to_sequence(sequence_id, email_address: nil, subscriber_id: nil)
        if subscriber_id
          request(:post, "/sequences/#{esc(sequence_id)}/subscribers/#{esc(subscriber_id)}")
        else
          request(:post, "/sequences/#{esc(sequence_id)}/subscribers", body: { email_address: email_address })
        end
      end

      def sequence_emails(sequence_id, **params)
        request(:get, "/sequences/#{esc(sequence_id)}/emails", params: params)
      end

      def sequence_email(sequence_id, id)
        request(:get, "/sequences/#{esc(sequence_id)}/emails/#{esc(id)}")
      end

      def create_sequence_email(sequence_id, subject:, delay_value:, delay_unit:, **attributes)
        request(:post, "/sequences/#{esc(sequence_id)}/emails",
          body: { subject: subject, delay_value: delay_value, delay_unit: delay_unit, **attributes })
      end

      def update_sequence_email(sequence_id, id, **attributes)
        request(:put, "/sequences/#{esc(sequence_id)}/emails/#{esc(id)}", body: attributes)
      end

      def delete_sequence_email(sequence_id, id)
        request(:delete, "/sequences/#{esc(sequence_id)}/emails/#{esc(id)}")
      end
    end
  end
end
