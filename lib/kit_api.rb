# frozen_string_literal: true

# The gem is named kit_api ("kit" was taken on rubygems) but defines the Kit
# module. This shim keeps Bundler's default require working.
require_relative "kit"
