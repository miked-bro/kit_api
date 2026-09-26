# frozen_string_literal: true

require_relative "test_helper"

class SimulatedTest < TestCase
  def setup
    super
    @driver = Kit::Simulated.new
  end

  def test_subscribe_records_the_call_and_invents_a_deterministic_id
    result = @driver.subscribe(email: "sam@example.com", first_name: "Sam", fields: { plan: "pro" })

    assert_equal [{ op: :subscribe, email: "sam@example.com", first_name: "Sam", fields: { plan: "pro" } }],
      Kit::Simulated.calls
    assert_match(/\Asim_\h{12}\z/, result[:subscriber_id])
    assert_equal result, @driver.subscribe(email: "sam@example.com", first_name: "Sam", fields: {})
  end

  def test_tag_and_unsubscribe_record_their_calls
    @driver.tag(email: "sam@example.com", tag: "customer")
    @driver.unsubscribe(email: "sam@example.com")

    assert_equal [
      { op: :tag, email: "sam@example.com", tag: "customer" },
      { op: :unsubscribe, email: "sam@example.com" }
    ], Kit::Simulated.calls
  end

  def test_reset_clears_recorded_calls
    @driver.tag(email: "sam@example.com", tag: "customer")
    Kit::Simulated.reset!

    assert_empty Kit::Simulated.calls
  end

  def test_low_level_methods_return_plausible_shapes
    page = @driver.subscribers(status: "active")
    assert_equal [], page["subscribers"]
    assert_equal false, page.dig("pagination", "has_next_page")

    assert_equal true, @driver.unsubscribe_subscriber(42)
    assert_equal({ "failures" => [] }, @driver.bulk_create_tags([{ name: "vip" }]))
    assert_equal "vip", @driver.create_tag("vip").dig("tag", "name")
  end

  def test_it_stays_silent_without_a_logger
    assert @driver.tag(email: "sam@example.com", tag: "quiet")
  end

  def test_it_logs_through_the_configured_logger
    messages = []
    logger = Struct.new(:messages) do
      def info(message) = messages << message
    end.new(messages)
    Kit.configure { |config| config.logger = logger }

    @driver.subscribe(email: "sam@example.com", first_name: "Sam")
    assert_equal ["[Kit simulated] subscribe sam@example.com"], messages
  end

  # The whole point of the driver: anything the real client can do, the fake
  # can absorb — same methods, same signatures. Grows a Client method? CI
  # fails here until Simulated grows the twin.
  def test_it_mirrors_the_client_surface_exactly
    client_methods = Kit::Client.public_instance_methods - Object.public_instance_methods
    simulated_methods = Kit::Simulated.public_instance_methods - Object.public_instance_methods

    assert_equal client_methods.sort, simulated_methods.sort

    client_methods.each do |name|
      assert_equal Kit::Client.instance_method(name).parameters,
        Kit::Simulated.instance_method(name).parameters,
        "signature drift on ##{name}"
    end
  end
end
