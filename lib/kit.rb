# frozen_string_literal: true

require_relative "kit/version"
require_relative "kit/client"
require_relative "kit/simulated"

# Kit (ConvertKit) v4 API client. Configure once, then call the high-level
# conveniences on the module or reach the full API surface via Kit.client.
#
#   Kit.configure do |config|
#     config.driver = :v4
#     config.api_key = "kit_..."
#   end
#
#   Kit.subscribe(email: "sam@example.com", first_name: "Sam")
#   Kit.client.broadcasts(per_page: 10)
module Kit
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  Config = Struct.new(:api_key, :access_token, :driver, :logger,
                      :open_timeout, :read_timeout, :base_url)

  def self.config
    @config ||= Config.new(nil, nil, :simulated, nil, 10, 20, "https://api.kit.com/v4")
  end

  def self.configure
    yield config
    @client = nil
  end

  # Plain ||= — concurrent first-touch can build a redundant client, which is
  # harmless (stateless but for the tag-name cache). Configure at boot.
  def self.client
    @client ||= case config.driver
    when :v4
      Client.new(api_key: config.api_key, access_token: config.access_token,
        base_url: config.base_url, open_timeout: config.open_timeout,
        read_timeout: config.read_timeout)
    when :simulated
      Simulated.new
    else
      raise Error, "Unknown Kit driver: #{config.driver.inspect} (use :v4 or :simulated)"
    end
  end

  def self.reset! = (@config = nil; @client = nil)

  def self.subscribe(email:, first_name:, fields: {})
    client.subscribe(email: email, first_name: first_name, fields: fields)
  end

  def self.tag(email:, tag:)
    client.tag(email: email, tag: tag)
  end

  def self.unsubscribe(email:)
    client.unsubscribe(email: email)
  end
end
