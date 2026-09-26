# frozen_string_literal: true

module Kit
  class Client
    module Segments
      def segments(**params)
        request(:get, "/segments", params: params)
      end
    end
  end
end
