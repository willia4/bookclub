require './exceptions/AuthorizationError.rb'
require './database/database.rb'

get '/admin/*' do
  pass if @session_state[:user_profile].user_status == 'admin'

  raise AuthorizationError.new("access admin area", "Only administrators may access admin functionality")
end

post '/admin/*' do
  pass if @session_state[:user_profile].user_status == 'admin'

  raise AuthorizationError.new("access admin area", "Only administrators may access admin functionality")
end

get '/admin/moderate/users' do
  @page_state[:page_title] = "Moderate Users"
  
  @profiles = Database::UserProfiles.list_user_profiles.sort

  erb :moderate_users
end

post '/admin/moderate/users' do
  profiles = Database::UserProfiles.list_user_profiles

  changed_profiles = []

  params.keys.each do |key|
    split = key.split("|")
    next unless split.size == 2

    user_id = split[0]
    input_id = split[1]

    profile = profiles.find { |p| p.user_id == user_id}
    next if profile.nil? 

    if input_id == "user_status"
      new_status = params[key]
      if new_status == "admin" || new_status == "confirmed" || new_status == "unconfirmed"
        if profile.user_status != new_status
          profile.user_status = new_status

          #don't add the same profile to the changed list twice
          found = changed_profiles.find { |c| c.user_id == profile.user_id}
          if found.nil?
            changed_profiles << profile
          end
        end
      end
    end
  end
  
  if changed_profiles.size > 0
    #create a set of all the changed profiles and the unchanged profiles
    #start with all the changed profiles
    merged_profiles = changed_profiles.map { |p| p }
    #for each profile, see if it's not already included. If not, add it. 
    profiles.each do |p|
      found = merged_profiles.find { |m| m.user_id == p.user_id }
      if found.nil?
        merged_profiles << p
      end
    end

    found = merged_profiles.select { |m| m.user_status == "admin" }
    if found.count == 0
      halt(400, "Must have at least one admin")
    end

    changed_profiles.each {|p| Database::UserProfiles.save_user_profile p}
  end

  redirect $config.make_url(request, "/admin/moderate/users"), 303
end