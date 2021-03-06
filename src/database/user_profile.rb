require 'securerandom'
require './database/sdb.rb'
require './database/redis.rb'
require './models/user_profile.rb'

module Database
  module UserProfiles
    def self.find_user_profile_by_user_id(request, user_id)
      item = Database::SDB.find_first_item_by_attribute("profiles", "user_id", user_id)
      return build_profile_from_sdb_item(request, item)
    end

    def self.find_user_profile_by_facebook_id(request, facebook_id) 
      item = Database::SDB.find_first_item_by_attribute("profiles", "facebook_id", facebook_id)
      return build_profile_from_sdb_item(request, item)
    end

    def self.save_user_profile profile 
      if profile.user_id.nil? || profile.user_id == ""
        #the first user should be an admin
        profile.user_status = "admin" if count_user_profiles == 0
        profile.user_id = SecureRandom.hex(16)  
      end

      attributes = Models::UserProfile.profile_properties.map do |p|
        value = profile.send(p).to_s
        { name: p, value: value, replace: true}
      end

      SDB.get_database_client.put_attributes( domain_name: SDB.build_domain("profiles"),
                        item_name: profile.user_id,
                        attributes: attributes)

      #cached profiles will be stale, so delete them from redis
      Redis.delete_sessions_for_user_profile(profile)
    end

    def self.delete_user_profile profile 
      #take either a user_id or a profile object 
      user_id = profile.respond_to?('user_id') ? profile.user_id : profile
      SDB.delete_items("profiles", user_id)

      #cached profiles are now invalid
      Redis.delete_sessions_for_user_profile(profile)
    end

    def self.count_user_profiles
      query = "select count(*) from #{SDB.build_domain("profiles")}"
      data = SDB.select(query)

      if data 
        return (data.items[0].attributes.select {|a| a.name = "Count"})[0].value.to_i
      end

      return 0
    end

    def self.list_user_profiles(request)
      query = "select * from #{SDB.build_domain("profiles")}"
      data = SDB.select(query)

      profiles = []
      data.each do |page|
        profiles.concat page.data.items.map { |i| build_profile_from_sdb_item(request, i) }
      end

      return profiles
    end

    def self.list_admin_user_profiles(request)
      query = "select * from #{SDB.build_domain("profiles")} where user_status = 'admin'"
      data = SDB.select(query)

      profiles = []
      data.each do |page|
        profiles.concat page.data.items.map { |i| build_profile_from_sdb_item(request, i) }
      end

      return profiles
    end

    def self.build_profile_from_sdb_item(request, item)
      return nil if item.nil? 

      profile = Models::UserProfile.new(request)

      Models::UserProfile.profile_properties.each do |p|
        value = SDB.find_attribute(item, p).to_s
        method = p + "="
        profile.send(method, value)
      end

      return profile
    end
  end
end