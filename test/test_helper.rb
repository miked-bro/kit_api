# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "kit_api"

require "minitest/autorun"
require "webmock/minitest"

class TestCase < Minitest::Test
  def setup
    Kit.reset!
    Kit::Simulated.reset!
  end

  private
    def json(payload, status: 200)
      { status: status, body: JSON.generate(payload),
        headers: { "Content-Type" => "application/json" } }
    end
end
