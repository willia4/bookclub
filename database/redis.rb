require './models/user_profile.rb'
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

    def self.find_session_keys_for_user_profile(profile)
      redis = get_database_client

      pattern = "session:*:user:#{profile.user_id}"
      keys = redis.keys(pattern)

      return keys || []
    end

    def self.delete_sessions_for_user_profile(profile)
      redis = get_database_client
      keys = find_session_keys_for_user_profile(profile)
      keys.each { |k| redis.del(k) }
    end

    def self.delete_session(session_token)
      redis = get_database_client
      pattern = "session:#{session_token}:*"
      keys = redis.keys(pattern)
      keys.each { |k| redis.del(k) }
    end

    def self.cache_css(file_name, modified_time, css)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      redis.set(key, css)
      redis.expire(key, 2 * 60 * 60)
    end

    def self.find_css(file_name, modified_time)
      redis = get_database_client
      key = "css:#{file_name}:mtime:#{modified_time}"
      return redis.get(key) #returns nil if not found
    end
  end
end