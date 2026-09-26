# frozen_string_literal: true

module Kit
  class Client
    module Accounts
      def account
        request(:get, "/account")
      end

      def account_colors
        request(:get, "/account/colors")
      end

      # Replaces the whole palette (up to 10 hex codes) — include every color to keep.
      def update_account_colors(colors)
        request(:put, "/account/colors", body: { colors: colors })
      end

      def creator_profile
        request(:get, "/account/creator_profile")
      end

      def email_stats
        request(:get, "/account/email_stats")
      end

      def growth_stats(**params)
        request(:get, "/account/growth_stats", params: params)
      end
    end
  end
end
