# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

require_relative "client/accounts"
require_relative "client/broadcasts"
require_relative "client/custom_fields"
require_relative "client/email_templates"
require_relative "client/forms"
require_relative "client/posts"
require_relative "client/purchases"
require_relative "client/segments"
require_relative "client/sequences"
require_relative "client/snippets"
require_relative "client/subscribers"
require_relative "client/tags"
require_relative "client/webhooks"

module Kit
  # The real Kit v4 API (https://developers.kit.com). One method per endpoint,
  # named resources/resource(id)/create_resource/verb_resource; each returns
  # the parsed JSON body as-is (204s return true). Pagination cursors pass
  # straight through: subscribers(after: cursor, per_page: 100).
  class Client
    include Accounts, Broadcasts, CustomFields, EmailTemplates, Forms, Posts,
            Purchases, Segments, Sequences, Snippets, Subscribers, Tags, Webhooks

    def initialize(api_key: nil, access_token: nil, base_url: "https://api.kit.com/v4",
                   open_timeout: 10, read_timeout: 20)
      raise Error, "Kit needs an api_key or an OAuth access_token" if api_key.nil? && access_token.nil?

      @api_key = api_key
      @access_token = access_token
      @base_url = base_url
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    # High-level conveniences, composed from the endpoint methods below.

    def subscribe(email:, first_name:, fields: {})
      body = create_subscriber(email_address: email, first_name: first_name, fields: fields)
      { subscriber_id: body.dig("subscriber", "id")&.to_s }
    end

    # Tags by name: resolved to an id once per client (created if missing) and
    # cached for the life of the process. Reconfiguring flushes the cache.
    def tag(email:, tag:)
      tag_subscriber(tag_id(tag), email_address: email)
      true
    end

    # The v4 API unsubscribes by subscriber id only, so look the id up first.
    # An address Kit doesn't know is already unsubscribed — succeed quietly.
    def unsubscribe(email:)
      subscriber = subscribers(email_address: email).fetch("subscribers", []).first
      return true unless subscriber

      unsubscribe_subscriber(subscriber["id"])
    end

    private
      # Ids land in URL paths; escaping keeps a hostile "42/unsubscribe"
      # from splicing itself into a different endpoint.
      def esc(id) = URI.encode_www_form_component(id.to_s)

      def tag_id(name)
        @tag_ids ||= {}
        @tag_ids[name] ||= begin
          existing, cursor = nil, nil
          loop do
            page = tags(per_page: 1000, after: cursor)
            existing = page.fetch("tags", []).find { |t| t["name"] == name }
            cursor = page.dig("pagination", "end_cursor")
            break if existing || !page.dig("pagination", "has_next_page")
          end
          (existing || create_tag(name).fetch("tag"))["id"]
        end
      end

      VERBS = {
        get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put,
        patch: Net::HTTP::Patch, delete: Net::HTTP::Delete
      }.freeze

      def request(method, path, params: nil, body: nil)
        uri = URI("#{@base_url}#{path}")
        query = params&.compact
        uri.query = URI.encode_www_form(query) unless query.nil? || query.empty?

        req = VERBS.fetch(method).new(uri.request_uri)
        if @access_token
          req["Authorization"] = "Bearer #{@access_token}"
        else
          req["X-Kit-Api-Key"] = @api_key
        end
        req["Accept"] = "application/json"
        if body
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(body)
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout

        response = http.request(req)
        unless response.code.start_with?("2")
          raise Error.new("Kit API #{response.code}: #{response.body.to_s[0, 200]}",
            status: response.code.to_i, body: response.body)
        end

        response.body.to_s.empty? ? true : JSON.parse(response.body)
      end
  end
end
