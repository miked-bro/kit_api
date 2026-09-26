# frozen_string_literal: true

module Kit
  class Client
    module Purchases
      def purchases(**params)
        request(:get, "/purchases", params: params)
      end

      def purchase(id)
        request(:get, "/purchases/#{esc(id)}")
      end

      # OAuth only. An existing transaction_id appends products instead of duplicating.
      def create_purchase(**attributes)
        request(:post, "/purchases", body: { purchase: attributes })
      end
    end
  end
end
