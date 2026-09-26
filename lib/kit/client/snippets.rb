# frozen_string_literal: true

module Kit
  class Client
    module Snippets
      def snippets(**params)
        request(:get, "/snippets", params: params)
      end

      def snippet(id)
        request(:get, "/snippets/#{id}")
      end

      # snippet_type: "inline" takes content:; "block" takes document_attributes:.
      def create_snippet(name:, **attributes)
        request(:post, "/snippets", body: { name: name, **attributes })
      end

      def update_snippet(id, **attributes)
        request(:put, "/snippets/#{id}", body: attributes)
      end
    end
  end
end
