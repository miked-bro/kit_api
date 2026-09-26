# frozen_string_literal: true

module Kit
  class Client
    module EmailTemplates
      def email_templates(**params)
        request(:get, "/email_templates", params: params)
      end
    end
  end
end
