# frozen_string_literal: true

module Kit
  class Client
    module Posts
      def posts(**params)
        request(:get, "/posts", params: params)
      end

      def post(id)
        request(:get, "/posts/#{id}")
      end
    end
  end
end
