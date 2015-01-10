require 'securerandom'
require './database/sdb.rb'
require './models/user_profile.rb'

module Database
  module UserSessions
    def self.create_user_session profile
      raise ArgumentError, "profile not specified" if profile.nil? 
      raise ArgumentError, "user_id not specified" if profile.user_id.nil? || profile.user_id == ""

      session_token = SecureRandom.hex(26).to_s
      now = Time.now.getutc.to_i
      expires = now + (60 * 24 * 60 * 60) #expire in 60 days

      attributes = [{name: "session_token", value: session_token, replace: true},
                    {name: "user_id", value: profile.user_id.to_s, replace: true},
                    {name: "expires", value: expires.to_s, replace: true}]

      sdb = SDB.get_database_client
      sdb.put_attributes(domain_name: SDB.build_domain("sessions"), item_name: session_token, attributes: attributes)

      return session_token
    end

    # Returns a profile if the session is valid or nil if it is not
    def self.validate_user_session session_token
      #clean up when validating just to keep the domain tidy
      cleanup_user_sessions
      now = Time.now.getutc.to_i

      query = "select user_id from #{SDB.build_domain("sessions")} where session_token = '#{session_token}' and expires >= '#{now}'"
      items = SDB.select(query).data.items
      item = items.count > 0 ? items[0] : nil
      return nil if item.nil?
      
      user_id = SDB.find_attribute(item, "user_id")
      return nil if user_id.nil? 

      profile = Database::UserProfiles.find_user_profile_by_user_id(user_id)
      return profile
    end

    def self.delete_user_session session_token
      Database::SDB.delete_items("sessions", session_token)
    end

    def self.cleanup_user_sessions
      SDB.expire_domain('sessions')
    end
  end
end