# frozen_string_literal: true

class User < ActiveRecord::Base
  has_timeline meta: { something: 'cool' }

  has_many :posts, dependent: :destroy
end

class Post < ActiveRecord::Base
  has_timeline

  belongs_to :user
end

class Comment < ActiveRecord::Base
  has_timeline

  belongs_to :post
end

# Create a simple test controller class for controller tests
module ModelTimeline
  module Test
    class TestController
      attr_accessor :request

      def initialize
        @request = OpenStruct.new(remote_ip: '192.168.1.1')
      end

      def current_user
        @current_user
      end

      def set_current_user(user)
        @current_user = user
      end
    end
  end
end
