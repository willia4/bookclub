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
  attr_accessor :avatar_url 

  attr_accessor :facebook_id
  attr_accessor :facebook_token
end