require './models/user_profile.rb'
require './models/book.rb'
require 'redis'

module Database
  module Redis
    def self.get_database_client
      if $redis_client.nil?
        config = $config[:redis]
        $redis_client = ::Redis.new(:host => config[:server], :port => config[:port], :db => config[:db])
      end

      return $redis_client
    end

    def self.delete_all_keys_matching_pattern(pattern)
      redis = get_database_client
      redis.keys(pattern).each { |key| redis.del(key) }
    end

    def self.store_session(session_token, session_profile)
      key = "session:#{session_token}:user:#{session_profile.user_id}"
      json = session_profile.to_json
      redis = get_database_client

      redis.set(key, json)
      redis.expire(key, 1 * 60 * 60) #expire in one hour
    end

    def self.find_user_profile_for_session(session_token)
      redis = get_database_client

      pattern = "session:#{session_token}:*"
      keys = redis.keys(pattern)

      if keys.size > 0 
        key = keys[0]
        json = redis.get(key)
        return Models::UserProfile.from_json(json)
      end

      return nil
    end

    def self.delete_sessions_for_user_profile(profile)
      delete_all_keys_matching_pattern("session:*:user:#{profile.user_id}")
    end

    def self.delete_session(session_token)
      redis = get_database_client
      pattern = "session:#{session_token}:*"
      keys = redis.keys(pattern)
      keys.each { |k| redis.del(k) }
    end

    def self.delete_all_sessions
      delete_all_keys_matching_pattern("session:*")
    end

    def self.store_book(book)
      redis = get_database_client
      key = "book:#{book.book_id}"
      redis.set(key, book.to_json)
      redis.expire(key, 2 * 60 * 60)
    end

    def self.find_book_by_book_id(book_id)
      redis = get_database_client
      json = redis.get("book:#{book_id}")
      return nil if json.nil? 
      return Models::Book.from_json(json)
    end

    def self.delete_book_id(book_id)
      redis = get_database_client
      redis.del("book:#{book_id}")
    end

    def self.delete_all_books
      delete_all_keys_matching_pattern("book:*")
    end

    def self.cache_css(file_name, modified_time, css)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      redis.set(key, css)
      redis.expire(key, 2 * 60 * 60) # two hours, if only because we don't want stale css hanging out taking up memory
    end

    def self.find_css(file_name, modified_time)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      return redis.get(key) #returns nil if not found
    end

    def self.delete_all_css
      delete_all_keys_matching_pattern("css:*")
    end
  end
end