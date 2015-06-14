require './models/user_profile.rb'
require './models/book.rb'
require 'redis'
require 'json'

module Database
  module Redis
    def self.get_database_client
      if $redis_client.nil?
        config = $config[:redis]
        $redis_client = ::Redis.new(:host => config[:server], :port => config[:port], :db => config[:db])
      end

      return $redis_client
    end

    def self.expiration_time_in_seconds
      #in dev mode, have things expire quickly (one hour)
      #in prod mode, have things expire slowly (30 days)
      base = ($config[:general][:mode] == "DEV" ? 1 * 60 * 60 : 30 * 24 * 60 * 60)

      #add a little bit of random jitter so a bunch of stuff doesn't expire all at the same time
      #since expiration for prod stuff is in days instead of hours, we need to have randomness in terms of days as well otehrwise it won't really matter
      if $config[:general][:mode] == "DEV" 
        #minutes
        jitter = Random.rand(-10..45) 
        jitter = jitter * 60
      else
        #days
        jitter = Random.rand(-2..5)
        jitter = jitter * 24 * 60 * 60
      end
      
      return base + jitter
    end

    def self.delete_all_keys
      delete_all_keys_matching_pattern("*")
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
      redis.expire(key, expiration_time_in_seconds)
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
      redis.expire(key, expiration_time_in_seconds)
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

    # votes should be an array of hashes
    def self.store_votes_for_meeting(meeting_id, votes)
      redis = get_database_client
      key = "votes:#{meeting_id}"
      votes = JSON.generate(votes)
      redis.set(key, votes)
      redis.expire(key, expiration_time_in_seconds)
    end

    def self.find_votes_for_meeting(meeting_id)
      redis = get_database_client
      key = "votes:#{meeting_id}"
      votes = redis.get(key)
      return nil if votes.nil?
      return JSON.parse(votes)
    end

    def self.delete_votes_for_meeting(meeting_id)
      key = "votes:#{meeting_id}"
      get_database_client.del(key)
    end

    def self.delete_all_votes
      delete_all_keys_matching_pattern("votes:*")
    end

    def self.cache_css(file_name, modified_time, css)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      redis.set(key, css)
      redis.expire(key, expiration_time_in_seconds)
    end

    def self.find_css(file_name, modified_time)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      return redis.get(key) #returns nil if not found
    end

    def self.delete_all_css
      delete_all_keys_matching_pattern("css:*")
    end

    def self.store_string(key, value)
      key = "text:#{key}"
      redis = get_database_client
      redis.set(key, value)
      redis.expire(key, expiration_time_in_seconds)
      value
    end

    def self.find_string(key)
      key = "text:#{key}"
      get_database_client.get(key)
    end

    def self.delete_string(key)
      key = "text:#{key}"
      get_database_client.del(key)
    end

    def self.delete_all_strings
      delete_all_keys_matching_pattern("text:*")
    end
  end
end