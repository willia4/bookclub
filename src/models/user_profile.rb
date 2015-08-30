require 'json'

module Models
  class UserProfile
    def self.profile_properties
      ["user_id", "user_status", "full_name", "casual_name", "email", "avatar_url", "facebook_id", "facebook_token"]
    end

    attr_accessor :user_id

    #"unconfirmed", "confirmed", "admin"
    attr_accessor :user_status

    attr_accessor :full_name
    attr_accessor :casual_name
    attr_accessor :email
    attr_writer :avatar_url 

    attr_accessor :facebook_id
    attr_accessor :facebook_token

    def initialize(request)
      @scheme = request.scheme
    end

    def avatar_url
      Database::S3.fixup_s3_url_for_https(@scheme, @avatar_url)
    end

    def <=> other
      return self.full_name <=> other.full_name
    end

    def to_json
      h = {}
      UserProfile.profile_properties.each do |p|
        h[p] = self.send(p)
      end

      h.to_json
    end

    def self.from_json(request, json_string)
      r = UserProfile.new(request)
      h = JSON.parse(json_string)

      UserProfile.profile_properties.each do |p|
        raise "Invalid JSON for Modules::UserProfile" if not h.keys.include?(p)

        method_name = p + "="
        
        r.send(method_name, h[p])
      end

      return r
    end
  end
end