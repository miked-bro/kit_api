# frozen_string_literal: true

require_relative "test_helper"

class KitTest < TestCase
  def test_defaults_to_the_simulated_driver
    assert_instance_of Kit::Simulated, Kit.client
  end

  def test_configure_sets_the_v4_driver
    Kit.configure do |config|
      config.driver = :v4
      config.api_key = "test-key"
    end

    assert_instance_of Kit::Client, Kit.client
  end

  def test_the_client_is_memoized
    assert_same Kit.client, Kit.client
  end

  def test_configure_invalidates_the_memoized_client
    first = Kit.client
    Kit.configure { |config| config.driver = :simulated }

    refute_same first, Kit.client
  end

  def test_reset_restores_defaults
    Kit.configure do |config|
      config.driver = :v4
      config.api_key = "test-key"
    end
    Kit.reset!

    assert_equal :simulated, Kit.config.driver
    assert_instance_of Kit::Simulated, Kit.client
  end

  def test_an_unknown_driver_raises
    Kit.configure { |config| config.driver = :smoke_signals }

    error = assert_raises(Kit::Error) { Kit.client }
    assert_match(/smoke_signals/, error.message)
  end

  def test_the_v4_driver_without_credentials_raises
    Kit.configure { |config| config.driver = :v4 }

    error = assert_raises(Kit::Error) { Kit.client }
    assert_match(/api_key/, error.message)
  end

  def test_module_conveniences_delegate_to_the_driver
    Kit.subscribe(email: "sam@example.com", first_name: "Sam", fields: { plan: "pro" })
    Kit.tag(email: "sam@example.com", tag: "customer")
    Kit.unsubscribe(email: "sam@example.com")

    assert_equal %i[subscribe tag unsubscribe], Kit::Simulated.calls.map { |call| call[:op] }
  end
end
