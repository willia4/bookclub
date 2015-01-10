require 'net/http'
require 'rack'
require 'json'

require './exceptions/AppError.rb'
require './database/database.rb'
require './apis/facebook.rb'
require './models/user_profile.rb'

class FacebookSigninError < AppError
  def initialize(reason)
    super("sign in via Facebook", reason)
  end
end

get '/signin/facebook/begin' do
  app_id = URI.encode($config[:facebook][:app_id].to_s)
  redirect_url = URI.encode(APIs::Facebook.login_finish_redirect_url)

  xsrf_token = Database::XSRFTokens.create_xsrf_token
  state = URI.encode(Database::XSRFTokens.create_xsrf_token)

  login_url = "https://www.facebook.com/dialog/oauth?client_id=#{app_id}&redirect_uri=#{redirect_url}&state=#{state}&scope=email"
  
  redirect login_url, 307
end

get '/signin/facebook/finish' do
  raise FacebookSigninError.new "Detected a potential Cross Site Scripting Attack: no state was returned by Facebook." if !params.has_key?("state")
  raise FacebookSigninError.new "Detected a potential Cross Site Scripting Attack: an invalid state was returned by Facebook." if !Database::XSRFTokens.validate_xsrf_token(params["state"])

  if params.has_key?("error")
    if params["error_reason"] = "user_denied"
      reason = "You denied us permissions to log in via Facebook" 
    else
      reason = params["error"] + ": " + params["error_description"]
    end

    raise FacebookSigninError.new(reason)
  end

  #turn the Facebook code into a token
  code = URI.encode(params["code"])
  token = APIs::Facebook.get_facebook_token_from_code code
  info = APIs::Facebook.inspect_facebook_token token 

  facebook_id = info["bio"]["id"]

  #look up the user to see if they already exist
  profile = Database::UserProfiles.find_user_profile_by_facebook_id(facebook_id)
  
  if profile.nil? 
    profile = Models::UserProfile.new
    profile.user_status = "unconfirmed"

    profile.full_name = info["bio"]["name"]
    profile.casual_name = info["bio"]["first_name"]
    profile.email = info["bio"]["email"]
    profile.avatar_url = nil

    profile.facebook_id = facebook_id
    profile.facebook_token = token

    Database::UserProfiles.save_user_profile(profile)
  end
  
  #facebook can give us a new token at their leisure. We should use the new one if it was changed.
  if profile.facebook_token != token
    profile.facebook_token = token
    Database::UserProfiles.save_user_profile(profile)
  end

  #create a user session for the user now that they've either signed or or created a new profile
  session_token = Database::UserSessions.create_user_session profile
  
  max_age_seconds = 59 * 24 * 60 * 60 #59 days, one day less than the session will expire in the database
  expires = Time.now + max_age_seconds

  response.set_cookie($config[:general][:login_cookie], :value => session_token,
                                                        :path => "/",
                                                        :expires => expires,
                                                        :max_age => max_age_seconds)

  redirect $config[:general][:base_url], 302
end
