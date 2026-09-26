# kit_api

A plain-Ruby client for the [Kit](https://kit.com) (formerly ConvertKit) **v4 API**. Zero runtime dependencies — `Net::HTTP` and stdlib JSON, nothing else — plus a first-class simulated driver so your tests never touch the network.

[![CI](https://github.com/miked-bro/kit_api/actions/workflows/ci.yml/badge.svg)](https://github.com/miked-bro/kit_api/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

## Installation

```ruby
gem "kit_api"
```

## Quickstart

```ruby
Kit.configure do |config|
  config.driver = :v4
  config.api_key = "kit_..."          # from Kit → Settings → Developer
  # config.access_token = "..."       # or an OAuth token instead
  # config.logger = Logger.new($stdout)
end

# High-level conveniences for the common lifecycle:
Kit.subscribe(email: "sam@example.com", first_name: "Sam", fields: { plan: "pro" })
# => { subscriber_id: "123" }

Kit.tag(email: "sam@example.com", tag: "customer")   # by tag NAME — created if missing
Kit.unsubscribe(email: "sam@example.com")
```

Everything else lives on the client, one method per documented endpoint:

```ruby
Kit.client.subscribers(status: "active", per_page: 100)
Kit.client.create_broadcast(subject: "News", content: "<p>Hi!</p>", ...)
Kit.client.add_subscriber_to_sequence(4, email_address: "sam@example.com")
```

Or build a client directly, no global config: `Kit::Client.new(api_key: "kit_...")`.

## The full surface

Methods return the parsed JSON body as-is (string keys); `204 No Content` returns `true`. Non-2xx responses raise `Kit::Error`, which carries `#status` and the raw `#body`.

| Resource | Methods |
| --- | --- |
| Subscribers | `subscribers` `subscriber` `create_subscriber` `update_subscriber` `unsubscribe_subscriber` `bulk_create_subscribers` `subscriber_stats` `subscriber_tags` `pin_subscriber_location` `update_subscriber_location` `delete_subscriber_location` |
| Tags | `tags` `create_tag` `update_tag` `tag_subscribers` `tag_subscriber` `untag_subscriber` `bulk_create_tags` `bulk_delete_tags` `bulk_tag_subscribers` `bulk_untag_subscribers` |
| Custom fields | `custom_fields` `create_custom_field` `update_custom_field` `delete_custom_field` `bulk_create_custom_fields` `bulk_update_subscriber_fields` |
| Forms | `forms` `form_subscribers` `add_subscriber_to_form` `bulk_add_subscribers_to_forms` |
| Sequences | `sequences` `sequence` `create_sequence` `update_sequence` `delete_sequence` `sequence_subscribers` `add_subscriber_to_sequence` `sequence_emails` `sequence_email` `create_sequence_email` `update_sequence_email` `delete_sequence_email` |
| Broadcasts | `broadcasts` `broadcast` `create_broadcast` `update_broadcast` `delete_broadcast` `broadcast_stats` `broadcasts_stats` `broadcast_clicks` |
| Account | `account` `account_colors` `update_account_colors` `creator_profile` `email_stats` `growth_stats` |
| Purchases | `purchases` `purchase` `create_purchase` |
| Webhooks | `webhooks` `webhook` `create_webhook` `update_webhook` `delete_webhook` `rotate_webhook_secret` `revoke_previous_webhook_secret` |
| And | `segments` · `snippets` `snippet` `create_snippet` `update_snippet` · `posts` `post` · `email_templates` |

Methods that reach a subscriber take either `email_address:` or `subscriber_id:`:

```ruby
Kit.client.tag_subscriber(5, email_address: "sam@example.com")
Kit.client.tag_subscriber(5, subscriber_id: 9)
```

## Pagination

Every list endpoint is cursor-paginated. Pass the cursors straight through:

```ruby
cursor = nil
loop do
  page = Kit.client.subscribers(per_page: 1000, after: cursor)
  page["subscribers"].each { |subscriber| ... }
  break unless page.dig("pagination", "has_next_page")
  cursor = page.dig("pagination", "end_cursor")
end
```

## Testing with the simulated driver

The simulated driver mirrors the real client's surface exactly (a test in this gem enforces it), records every call, and talks to no one:

```ruby
# The default driver is already :simulated — no configuration needed in tests.
class FunnelTest < ActiveSupport::TestCase
  setup { Kit::Simulated.reset! }

  test "signing up subscribes the lead" do
    post signups_path, params: { email: "sam@example.com" }

    subscribe = Kit::Simulated.calls.find { |call| call[:op] == :subscribe }
    assert_equal "sam@example.com", subscribe[:email]
  end
end
```

`Kit::Simulated.calls` is an array of `{ op:, **arguments }` hashes; `subscribe` returns deterministic ids (`"sim_<sha256 prefix>"`) so records that store a `subscriber_id` behave realistically.

## Rails

```ruby
# config/initializers/kit.rb
Kit.configure do |config|
  config.driver  = Rails.env.production? ? :v4 : :simulated
  config.api_key = Rails.application.credentials.dig(:kit, :api_key)
  config.logger  = Rails.logger
end
```

## Good to know

- **No automatic retries.** Rate limits (120 requests/minute with an API key, 600 with OAuth) and transient failures raise `Kit::Error`; retry where you understand idempotency — e.g. `retry_on Kit::Error` in an Active Job.
- **OAuth-only endpoints.** Kit restricts the `bulk_*` methods and `create_purchase` to OAuth tokens; with an API key the API returns its own error.
- **Tag names are cached.** `Kit.tag`/`Kit.client.tag(email:, tag:)` resolves names to ids once per client. Renaming a tag in the Kit UI mid-process can leave a stale id; reconfigure (or build a fresh client) to flush.
- **Custom fields must exist.** Values in `fields:` only stick for custom fields already defined in your Kit account — create them in the UI or via `create_custom_field(label: "Plan")`.

## License

[MIT](LICENSE.txt)
