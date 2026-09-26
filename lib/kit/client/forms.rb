# frozen_string_literal: true

module Kit
  class Client
    module Forms
      def forms(**params)
        request(:get, "/forms", params: params)
      end

      def form_subscribers(id, **params)
        request(:get, "/forms/#{esc(id)}/subscribers", params: params)
      end

      def add_subscriber_to_form(form_id, email_address: nil, subscriber_id: nil, referrer: nil)
        if subscriber_id
          request(:post, "/forms/#{esc(form_id)}/subscribers/#{esc(subscriber_id)}", body: { referrer: referrer }.compact)
        else
          request(:post, "/forms/#{esc(form_id)}/subscribers",
            body: { email_address: email_address, referrer: referrer }.compact)
        end
      end

      # Additions are { form_id:, subscriber_id:, referrer: } objects.
      def bulk_add_subscribers_to_forms(additions, callback_url: nil)
        request(:post, "/bulk/forms/subscribers",
          body: { additions: additions, callback_url: callback_url }.compact)
      end
    end
  end
end
