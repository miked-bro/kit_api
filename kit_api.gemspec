# frozen_string_literal: true

require_relative "lib/kit/version"

Gem::Specification.new do |spec|
  spec.name = "kit_api"
  spec.version = Kit::VERSION
  spec.authors = ["Mike D"]
  spec.email = ["mojonickle@gmail.com"]

  spec.summary = "Kit (ConvertKit) v4 API client with zero dependencies."
  spec.description = "A plain-Ruby client for the Kit (formerly ConvertKit) v4 API: subscribers, " \
                     "tags, custom fields, forms, sequences, broadcasts, purchases, webhooks and more. " \
                     "Net::HTTP and stdlib JSON only, plus a first-class simulated driver for tests."
  spec.homepage = "https://github.com/miked-bro/kit_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb"] + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]
end
