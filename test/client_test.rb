# frozen_string_literal: true

require_relative "test_helper"

class ClientTest < TestCase
  BASE = "https://api.kit.com/v4"

  def setup
    super
    @client = Kit::Client.new(api_key: "test-key")
  end

  def test_a_credential_is_required
    error = assert_raises(Kit::Error) { Kit::Client.new }
    assert_match(/api_key/, error.message)
  end

  def test_requests_authenticate_with_the_api_key_header
    stub = stub_request(:get, "#{BASE}/tags")
      .with(headers: { "X-Kit-Api-Key" => "test-key", "Accept" => "application/json" })
      .to_return(json({ tags: [] }))

    @client.tags
    assert_requested(stub)
  end

  def test_an_access_token_authenticates_with_a_bearer_header
    stub = stub_request(:get, "#{BASE}/tags")
      .with(headers: { "Authorization" => "Bearer oauth-token" })
      .to_return(json({ tags: [] }))

    Kit::Client.new(access_token: "oauth-token").tags
    assert_requested(stub)
  end

  def test_subscribe_creates_a_subscriber_and_returns_its_id
    stub_request(:post, "#{BASE}/subscribers")
      .with(body: { email_address: "sam@example.com", first_name: "Sam", fields: { plan: "pro" } })
      .to_return(json({ subscriber: { id: 123, email_address: "sam@example.com" } }, status: 201))

    result = @client.subscribe(email: "sam@example.com", first_name: "Sam", fields: { plan: "pro" })
    assert_equal({ subscriber_id: "123" }, result)
  end

  def test_tag_resolves_the_name_once_and_caches_the_id
    lookup = stub_request(:get, "#{BASE}/tags?per_page=1000")
      .to_return(json({ tags: [{ id: 5, name: "customer" }], pagination: { has_next_page: false } }))
    tagging = stub_request(:post, "#{BASE}/tags/5/subscribers")
      .with(body: { email_address: "sam@example.com" })
      .to_return(json({ subscriber: { id: 123 } }))

    2.times { assert_equal true, @client.tag(email: "sam@example.com", tag: "customer") }

    assert_requested(lookup, times: 1)
    assert_requested(tagging, times: 2)
  end

  def test_tag_creates_the_tag_when_missing
    stub_request(:get, "#{BASE}/tags?per_page=1000")
      .to_return(json({ tags: [], pagination: { has_next_page: false } }))
    stub_request(:post, "#{BASE}/tags")
      .with(body: { name: "brand-new" })
      .to_return(json({ tag: { id: 9, name: "brand-new" } }, status: 201))
    tagging = stub_request(:post, "#{BASE}/tags/9/subscribers").to_return(json({ subscriber: { id: 1 } }))

    @client.tag(email: "sam@example.com", tag: "brand-new")
    assert_requested(tagging)
  end

  def test_tag_lookup_follows_pagination_cursors
    stub_request(:get, "#{BASE}/tags?per_page=1000")
      .to_return(json({ tags: [{ id: 1, name: "other" }],
                        pagination: { has_next_page: true, end_cursor: "abc" } }))
    stub_request(:get, "#{BASE}/tags?per_page=1000&after=abc")
      .to_return(json({ tags: [{ id: 7, name: "deep-cut" }], pagination: { has_next_page: false } }))
    tagging = stub_request(:post, "#{BASE}/tags/7/subscribers").to_return(json({ subscriber: { id: 1 } }))

    @client.tag(email: "sam@example.com", tag: "deep-cut")
    assert_requested(tagging)
  end

  def test_unsubscribe_looks_the_subscriber_up_by_email
    stub_request(:get, "#{BASE}/subscribers?email_address=sam@example.com")
      .to_return(json({ subscribers: [{ id: 42 }] }))
    stub_request(:post, "#{BASE}/subscribers/42/unsubscribe").to_return(status: 204, body: "")

    assert_equal true, @client.unsubscribe(email: "sam@example.com")
  end

  def test_unsubscribing_an_unknown_email_is_a_quiet_no_op
    stub_request(:get, "#{BASE}/subscribers?email_address=gone@example.com")
      .to_return(json({ subscribers: [] }))

    assert_equal true, @client.unsubscribe(email: "gone@example.com")
    assert_not_requested(:post, %r{/unsubscribe})
  end

  def test_list_params_become_query_strings
    stub = stub_request(:get, "#{BASE}/subscribers?after=abc&per_page=10&status=active")
      .to_return(json({ subscribers: [] }))

    @client.subscribers(after: "abc", per_page: 10, status: "active", created_after: nil)
    assert_requested(stub)
  end

  def test_a_non_2xx_response_raises_a_kit_error
    stub_request(:post, "#{BASE}/subscribers")
      .to_return(status: 422, body: JSON.generate(errors: ["Email address is invalid"]))

    error = assert_raises(Kit::Error) { @client.create_subscriber(email_address: "nope") }
    assert_equal 422, error.status
    assert_match(/Kit API 422/, error.message)
    assert_match(/invalid/, error.body)
  end

  def test_ids_cannot_splice_into_a_different_endpoint
    stub = stub_request(:get, "#{BASE}/subscribers/42%2Funsubscribe").to_return(json({}))

    @client.subscriber("42/unsubscribe")

    assert_requested(stub)
    assert_not_requested(:post, %r{/unsubscribe})
  end

  def test_a_204_returns_true
    stub_request(:delete, "#{BASE}/custom_fields/3").to_return(status: 204, body: "")

    assert_equal true, @client.delete_custom_field(3)
  end

  def test_bulk_deletes_send_a_json_body
    stub = stub_request(:delete, "#{BASE}/bulk/tags")
      .with(body: { tags: [{ id: 5 }] })
      .to_return(json({ failures: [] }))

    @client.bulk_delete_tags([{ id: 5 }])
    assert_requested(stub)
  end

  # One entry per endpoint: proves each method hits its documented verb + path.
  SURFACE = [
    [:get,    "/subscribers",                        ->(c) { c.subscribers }],
    [:get,    "/subscribers/1",                      ->(c) { c.subscriber(1) }],
    [:post,   "/subscribers",                        ->(c) { c.create_subscriber(email_address: "s@e.com") }],
    [:put,    "/subscribers/1",                      ->(c) { c.update_subscriber(1, first_name: "Sam") }],
    [:post,   "/subscribers/1/unsubscribe",          ->(c) { c.unsubscribe_subscriber(1) }],
    [:post,   "/bulk/subscribers",                   ->(c) { c.bulk_create_subscribers([{ email_address: "s@e.com" }]) }],
    [:get,    "/subscribers/1/stats",                ->(c) { c.subscriber_stats(1) }],
    [:get,    "/subscribers/1/tags",                 ->(c) { c.subscriber_tags(1) }],
    [:post,   "/subscribers/1/location",             ->(c) { c.pin_subscriber_location(1, country_code: "US") }],
    [:patch,  "/subscribers/1/location",             ->(c) { c.update_subscriber_location(1, country_code: "US") }],
    [:delete, "/subscribers/1/location",             ->(c) { c.delete_subscriber_location(1) }],
    [:get,    "/tags",                               ->(c) { c.tags }],
    [:post,   "/tags",                               ->(c) { c.create_tag("vip") }],
    [:put,    "/tags/5",                             ->(c) { c.update_tag(5, name: "vip") }],
    [:get,    "/tags/5/subscribers",                 ->(c) { c.tag_subscribers(5) }],
    [:post,   "/tags/5/subscribers",                 ->(c) { c.tag_subscriber(5, email_address: "s@e.com") }],
    [:post,   "/tags/5/subscribers/9",               ->(c) { c.tag_subscriber(5, subscriber_id: 9) }],
    [:delete, "/tags/5/subscribers?email_address=s@e.com", ->(c) { c.untag_subscriber(5, email_address: "s@e.com") }],
    [:delete, "/tags/5/subscribers/9",               ->(c) { c.untag_subscriber(5, subscriber_id: 9) }],
    [:post,   "/bulk/tags",                          ->(c) { c.bulk_create_tags([{ name: "vip" }]) }],
    [:delete, "/bulk/tags",                          ->(c) { c.bulk_delete_tags([{ id: 5 }]) }],
    [:post,   "/bulk/tags/subscribers",              ->(c) { c.bulk_tag_subscribers([{ tag_id: 5, subscriber_id: 9 }]) }],
    [:delete, "/bulk/tags/subscribers",              ->(c) { c.bulk_untag_subscribers([{ tag_id: 5, subscriber_id: 9 }]) }],
    [:get,    "/custom_fields",                      ->(c) { c.custom_fields }],
    [:post,   "/custom_fields",                      ->(c) { c.create_custom_field(label: "Plan") }],
    [:put,    "/custom_fields/3",                    ->(c) { c.update_custom_field(3, label: "Plan") }],
    [:delete, "/custom_fields/3",                    ->(c) { c.delete_custom_field(3) }],
    [:post,   "/bulk/custom_fields",                 ->(c) { c.bulk_create_custom_fields([{ label: "Plan" }]) }],
    [:post,   "/bulk/custom_fields/subscribers",     ->(c) { c.bulk_update_subscriber_fields([{ subscriber_id: 1, subscriber_custom_field_id: 2, value: "pro" }]) }],
    [:get,    "/forms",                              ->(c) { c.forms }],
    [:get,    "/forms/2/subscribers",                ->(c) { c.form_subscribers(2) }],
    [:post,   "/forms/2/subscribers",                ->(c) { c.add_subscriber_to_form(2, email_address: "s@e.com") }],
    [:post,   "/forms/2/subscribers/9",              ->(c) { c.add_subscriber_to_form(2, subscriber_id: 9, referrer: "https://e.com") }],
    [:post,   "/bulk/forms/subscribers",             ->(c) { c.bulk_add_subscribers_to_forms([{ form_id: 2, subscriber_id: 9 }]) }],
    [:get,    "/sequences",                          ->(c) { c.sequences }],
    [:get,    "/sequences/4",                        ->(c) { c.sequence(4) }],
    [:post,   "/sequences",                          ->(c) { c.create_sequence(name: "Welcome") }],
    [:put,    "/sequences/4",                        ->(c) { c.update_sequence(4, name: "Welcome") }],
    [:delete, "/sequences/4",                        ->(c) { c.delete_sequence(4) }],
    [:get,    "/sequences/4/subscribers",            ->(c) { c.sequence_subscribers(4) }],
    [:post,   "/sequences/4/subscribers",            ->(c) { c.add_subscriber_to_sequence(4, email_address: "s@e.com") }],
    [:post,   "/sequences/4/subscribers/9",          ->(c) { c.add_subscriber_to_sequence(4, subscriber_id: 9) }],
    [:get,    "/sequences/4/emails",                 ->(c) { c.sequence_emails(4) }],
    [:get,    "/sequences/4/emails/7",               ->(c) { c.sequence_email(4, 7) }],
    [:post,   "/sequences/4/emails",                 ->(c) { c.create_sequence_email(4, subject: "Hi", delay_value: 1, delay_unit: "days") }],
    [:put,    "/sequences/4/emails/7",               ->(c) { c.update_sequence_email(4, 7, subject: "Hi") }],
    [:delete, "/sequences/4/emails/7",               ->(c) { c.delete_sequence_email(4, 7) }],
    [:get,    "/broadcasts",                         ->(c) { c.broadcasts }],
    [:get,    "/broadcasts/8",                       ->(c) { c.broadcast(8) }],
    [:post,   "/broadcasts",                         ->(c) { c.create_broadcast(subject: "News") }],
    [:put,    "/broadcasts/8",                       ->(c) { c.update_broadcast(8, subject: "News") }],
    [:delete, "/broadcasts/8",                       ->(c) { c.delete_broadcast(8) }],
    [:get,    "/broadcasts/8/stats",                 ->(c) { c.broadcast_stats(8) }],
    [:get,    "/broadcasts/stats",                   ->(c) { c.broadcasts_stats }],
    [:get,    "/broadcasts/8/clicks",                ->(c) { c.broadcast_clicks(8) }],
    [:get,    "/account",                            ->(c) { c.account }],
    [:get,    "/account/colors",                     ->(c) { c.account_colors }],
    [:put,    "/account/colors",                     ->(c) { c.update_account_colors(["#000000"]) }],
    [:get,    "/account/creator_profile",            ->(c) { c.creator_profile }],
    [:get,    "/account/email_stats",                ->(c) { c.email_stats }],
    [:get,    "/account/growth_stats",               ->(c) { c.growth_stats }],
    [:get,    "/purchases",                          ->(c) { c.purchases }],
    [:get,    "/purchases/6",                        ->(c) { c.purchase(6) }],
    [:post,   "/purchases",                          ->(c) { c.create_purchase(email_address: "s@e.com", transaction_id: "t1") }],
    [:get,    "/segments",                           ->(c) { c.segments }],
    [:get,    "/snippets",                           ->(c) { c.snippets }],
    [:get,    "/snippets/2",                         ->(c) { c.snippet(2) }],
    [:post,   "/snippets",                           ->(c) { c.create_snippet(name: "Sig", snippet_type: "inline", content: "Bye") }],
    [:put,    "/snippets/2",                         ->(c) { c.update_snippet(2, name: "Sig") }],
    [:get,    "/posts",                              ->(c) { c.posts }],
    [:get,    "/posts/3",                            ->(c) { c.post(3) }],
    [:get,    "/email_templates",                    ->(c) { c.email_templates }],
    [:get,    "/webhook_endpoints",                  ->(c) { c.webhooks }],
    [:get,    "/webhook_endpoints/1",                ->(c) { c.webhook(1) }],
    [:post,   "/webhook_endpoints",                  ->(c) { c.create_webhook(url: "https://e.com/hook", events: ["subscriber.created"]) }],
    [:put,    "/webhook_endpoints/1",                ->(c) { c.update_webhook(1, name: "Hook") }],
    [:delete, "/webhook_endpoints/1",                ->(c) { c.delete_webhook(1) }],
    [:post,   "/webhook_endpoints/1/rotate_secret",  ->(c) { c.rotate_webhook_secret(1) }],
    [:post,   "/webhook_endpoints/1/revoke_previous_secret", ->(c) { c.revoke_previous_webhook_secret(1) }]
  ].freeze

  def test_every_endpoint_hits_its_documented_verb_and_path
    SURFACE.each do |verb, path, call|
      WebMock.reset!
      stub = stub_request(verb, "#{BASE}#{path}").to_return(json({}))

      call.call(@client)
      assert_requested(stub)
    end
  end
end
