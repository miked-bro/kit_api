# frozen_string_literal: true

require "digest"

module Kit
  # Dev/test driver: records every call, invents ids, talks to no one. Same
  # public surface as Client (a test enforces parity), so code under test can
  # assert on Kit::Simulated.calls instead of stubbing HTTP:
  #
  #   Kit::Simulated.reset!
  #   Kit.subscribe(email: "sam@example.com", first_name: "Sam")
  #   Kit::Simulated.calls  # => [{ op: :subscribe, email: "sam@example.com", ... }]
  class Simulated
    def self.calls = @calls ||= []
    def self.reset! = @calls = []

    PAGE = { "has_previous_page" => false, "has_next_page" => false,
             "start_cursor" => nil, "end_cursor" => nil, "per_page" => 500 }.freeze

    # High-level conveniences

    def subscribe(email:, first_name:, fields: {})
      record(:subscribe, email: email, first_name: first_name, fields: fields)
      { subscriber_id: sim_id(email) }
    end

    def tag(email:, tag:)
      record(:tag, email: email, tag: tag)
      true
    end

    def unsubscribe(email:)
      record(:unsubscribe, email: email)
      true
    end

    # Subscribers

    def subscribers(**params) = record_page(:subscribers, "subscribers", **params)
    def subscriber(id) = record_one(:subscriber, "subscriber", id, id: id)

    def create_subscriber(email_address:, **attributes)
      record(:create_subscriber, email_address: email_address, **attributes)
      { "subscriber" => { "id" => sim_id(email_address), "email_address" => email_address,
                          "state" => "active", **attributes.transform_keys(&:to_s) } }
    end

    def update_subscriber(id, **attributes) = record_one(:update_subscriber, "subscriber", id, id: id, **attributes)
    def unsubscribe_subscriber(id) = record(:unsubscribe_subscriber, id: id)
    def bulk_create_subscribers(subscribers, callback_url: nil) = record_bulk(:bulk_create_subscribers, subscribers: subscribers, callback_url: callback_url)
    def subscriber_stats(id, **params) = record_one(:subscriber_stats, "subscriber", id, id: id, **params)
    def subscriber_tags(id, **params) = record_page(:subscriber_tags, "tags", id: id, **params)
    def pin_subscriber_location(id, **location) = record_one(:pin_subscriber_location, "subscriber", id, id: id, **location)
    def update_subscriber_location(id, **location) = record_one(:update_subscriber_location, "subscriber", id, id: id, **location)
    def delete_subscriber_location(id) = record(:delete_subscriber_location, id: id)

    # Tags

    def tags(**params) = record_page(:tags, "tags", **params)

    def create_tag(name)
      record(:create_tag, name: name)
      { "tag" => { "id" => sim_id(name), "name" => name } }
    end

    def update_tag(id, name:) = record_one(:update_tag, "tag", id, id: id, name: name)
    def tag_subscribers(id, **params) = record_page(:tag_subscribers, "subscribers", id: id, **params)

    def tag_subscriber(tag_id, email_address: nil, subscriber_id: nil)
      record(:tag_subscriber, tag_id: tag_id, email_address: email_address, subscriber_id: subscriber_id)
      { "subscriber" => { "id" => subscriber_id || sim_id(email_address.to_s) } }
    end

    def untag_subscriber(tag_id, email_address: nil, subscriber_id: nil)
      record(:untag_subscriber, tag_id: tag_id, email_address: email_address, subscriber_id: subscriber_id)
    end

    def bulk_create_tags(tags, callback_url: nil) = record_bulk(:bulk_create_tags, tags: tags, callback_url: callback_url)
    def bulk_delete_tags(tags, callback_url: nil) = record_bulk(:bulk_delete_tags, tags: tags, callback_url: callback_url)
    def bulk_tag_subscribers(taggings, callback_url: nil) = record_bulk(:bulk_tag_subscribers, taggings: taggings, callback_url: callback_url)
    def bulk_untag_subscribers(taggings, callback_url: nil) = record_bulk(:bulk_untag_subscribers, taggings: taggings, callback_url: callback_url)

    # Custom fields

    def custom_fields(**params) = record_page(:custom_fields, "custom_fields", **params)

    def create_custom_field(label:)
      record(:create_custom_field, label: label)
      { "custom_field" => { "id" => sim_id(label), "label" => label } }
    end

    def update_custom_field(id, label:) = record_one(:update_custom_field, "custom_field", id, id: id, label: label)
    def delete_custom_field(id) = record(:delete_custom_field, id: id)
    def bulk_create_custom_fields(custom_fields, callback_url: nil) = record_bulk(:bulk_create_custom_fields, custom_fields: custom_fields, callback_url: callback_url)
    def bulk_update_subscriber_fields(custom_field_values, callback_url: nil) = record_bulk(:bulk_update_subscriber_fields, custom_field_values: custom_field_values, callback_url: callback_url)

    # Forms

    def forms(**params) = record_page(:forms, "forms", **params)
    def form_subscribers(id, **params) = record_page(:form_subscribers, "subscribers", id: id, **params)

    def add_subscriber_to_form(form_id, email_address: nil, subscriber_id: nil, referrer: nil)
      record(:add_subscriber_to_form, form_id: form_id, email_address: email_address,
        subscriber_id: subscriber_id, referrer: referrer)
      { "subscriber" => { "id" => subscriber_id || sim_id(email_address.to_s) } }
    end

    def bulk_add_subscribers_to_forms(additions, callback_url: nil) = record_bulk(:bulk_add_subscribers_to_forms, additions: additions, callback_url: callback_url)

    # Sequences

    def sequences(**params) = record_page(:sequences, "sequences", **params)
    def sequence(id) = record_one(:sequence, "sequence", id, id: id)

    def create_sequence(name:, **attributes)
      record(:create_sequence, name: name, **attributes)
      { "sequence" => { "id" => sim_id(name), "name" => name } }
    end

    def update_sequence(id, **attributes) = record_one(:update_sequence, "sequence", id, id: id, **attributes)
    def delete_sequence(id) = record(:delete_sequence, id: id)
    def sequence_subscribers(id, **params) = record_page(:sequence_subscribers, "subscribers", id: id, **params)

    def add_subscriber_to_sequence(sequence_id, email_address: nil, subscriber_id: nil)
      record(:add_subscriber_to_sequence, sequence_id: sequence_id, email_address: email_address,
        subscriber_id: subscriber_id)
      { "subscriber" => { "id" => subscriber_id || sim_id(email_address.to_s) } }
    end

    def sequence_emails(sequence_id, **params) = record_page(:sequence_emails, "emails", sequence_id: sequence_id, **params)
    def sequence_email(sequence_id, id) = record_one(:sequence_email, "email", id, sequence_id: sequence_id, id: id)

    def create_sequence_email(sequence_id, subject:, delay_value:, delay_unit:, **attributes)
      record(:create_sequence_email, sequence_id: sequence_id, subject: subject,
        delay_value: delay_value, delay_unit: delay_unit, **attributes)
      { "email" => { "id" => sim_id(subject), "sequence_id" => sequence_id, "subject" => subject } }
    end

    def update_sequence_email(sequence_id, id, **attributes) = record_one(:update_sequence_email, "email", id, sequence_id: sequence_id, id: id, **attributes)
    def delete_sequence_email(sequence_id, id) = record(:delete_sequence_email, sequence_id: sequence_id, id: id)

    # Broadcasts

    def broadcasts(**params) = record_page(:broadcasts, "broadcasts", **params)
    def broadcast(id) = record_one(:broadcast, "broadcast", id, id: id)

    def create_broadcast(**attributes)
      record(:create_broadcast, **attributes)
      { "broadcast" => { "id" => sim_id(attributes.inspect), **attributes.transform_keys(&:to_s) } }
    end

    def update_broadcast(id, **attributes) = record_one(:update_broadcast, "broadcast", id, id: id, **attributes)
    def delete_broadcast(id) = record(:delete_broadcast, id: id)
    def broadcast_stats(id) = record_one(:broadcast_stats, "broadcast", id, id: id)
    def broadcasts_stats(**params) = record_page(:broadcasts_stats, "broadcasts", **params)
    def broadcast_clicks(id, **params) = record_one(:broadcast_clicks, "broadcast", id, id: id, **params)

    # Account

    def account = record_one(:account, "account", "sim_account")
    def account_colors = (record(:account_colors); { "colors" => [] })
    def update_account_colors(colors) = (record(:update_account_colors, colors: colors); { "colors" => colors })
    def creator_profile = record_one(:creator_profile, "profile", "sim_profile")
    def email_stats = record_one(:email_stats, "stats", "sim_stats")
    def growth_stats(**params) = record_one(:growth_stats, "stats", "sim_stats", **params)

    # Purchases

    def purchases(**params) = record_page(:purchases, "purchases", **params)
    def purchase(id) = record_one(:purchase, "purchase", id, id: id)

    def create_purchase(**attributes)
      record(:create_purchase, **attributes)
      { "purchase" => { "id" => sim_id(attributes.inspect), **attributes.transform_keys(&:to_s) } }
    end

    # Segments, snippets, posts, email templates

    def segments(**params) = record_page(:segments, "segments", **params)
    def snippets(**params) = record_page(:snippets, "snippets", **params)
    def snippet(id) = record_one(:snippet, "snippet", id, id: id)

    def create_snippet(name:, **attributes)
      record(:create_snippet, name: name, **attributes)
      { "snippet" => { "id" => sim_id(name), "name" => name } }
    end

    def update_snippet(id, **attributes) = record_one(:update_snippet, "snippet", id, id: id, **attributes)
    def posts(**params) = record_page(:posts, "posts", **params)
    def post(id) = record_one(:post, "post", id, id: id)
    def email_templates(**params) = record_page(:email_templates, "email_templates", **params)

    # Webhooks

    def webhooks(**params) = record_page(:webhooks, "webhook_endpoints", **params)
    def webhook(id) = record_one(:webhook, "webhook_endpoint", id, id: id)

    def create_webhook(url:, events:, **attributes)
      record(:create_webhook, url: url, events: events, **attributes)
      { "webhook_endpoint" => { "id" => sim_id(url), "url" => url, "events" => events, "secret" => "whsec_simulated" } }
    end

    def update_webhook(id, **attributes) = record_one(:update_webhook, "webhook_endpoint", id, id: id, **attributes)
    def delete_webhook(id) = record(:delete_webhook, id: id)
    def rotate_webhook_secret(id, force: nil) = record_one(:rotate_webhook_secret, "webhook_endpoint", id, id: id, force: force)
    def revoke_previous_webhook_secret(id) = record_one(:revoke_previous_webhook_secret, "webhook_endpoint", id, id: id)

    private
      def record(op, **kwargs)
        self.class.calls << { op: op, **kwargs }
        Kit.config.logger&.info("[Kit simulated] #{op} #{kwargs.values.first}")
        true
      end

      def record_page(op, key, **kwargs)
        record(op, **kwargs)
        { key => [], "pagination" => PAGE.dup }
      end

      def record_one(op, key, id, **kwargs)
        record(op, **kwargs)
        { key => { "id" => id } }
      end

      def record_bulk(op, **kwargs)
        record(op, **kwargs.compact)
        { "failures" => [] }
      end

      def sim_id(seed) = "sim_#{Digest::SHA256.hexdigest(seed.to_s)[0, 12]}"
  end
end
