require 'aws-sdk-core'
require 'securerandom'
require './user_profile.rb'

module Database
	module Debug
		def self.delete_all_sessions
			sessions = list_all_sessions
			Database::SDB.delete_items('sessions', sessions.map { |s| s[:session_token] })
		end

		def self.list_all_sessions
			query = "select * from #{Database::SDB.build_domain("sessions")}"
			data = Database::SDB.get_database_client.select(select_expression: query)
			sessions = []
			data.each do |page|
				sessions.concat(page.data.items.map do |item|
					{
						session_token: Database::SDB.find_attribute(item, "session_token"),
						user_id: Database::SDB.find_attribute(item, "user_id"),
						expires: Database::SDB.find_attribute(item, "expires")
					}
				end)
			end
			sessions
		end

		def self.delete_all_profiles
			profiles = Database.list_user_profiles
			Database::SDB.delete_items('profiles', profiles.map { |p| p.user_id })
		end
	end

	module SDB
		def self.get_database_client
			if $sdb_client.nil?
				config = $config[:aws][:sdb]

				$sdb_client = Aws::SimpleDB::Client.new(
								region: config[:region], 
								access_key_id: config[:access_key],
								secret_access_key: config[:secret])
			end

			return $sdb_client
		end

		def self.find_attribute attributes, key
			#support someone passing in the item instead of the item's attributes
			if attributes.respond_to? "attributes"
				attributes = attributes.attributes
			end

			a = attributes.select {|s| s.name == key }

			return a[0].value if a.count > 0 

			return nil
		end

		def self.build_domain(domain)
			prefix = $config[:aws][:sdb][:domain_prefix]
			domain = prefix + domain unless domain.start_with?(prefix)

			return domain
		end

		def self.delete_domains
			prefix = $config[:aws][:sdb][:domain_prefix]

			sdb = get_database_client
			list_domains(prefix).each do |n|
				sdb.delete_domain domain_name: n
			end
		end

		def self.list_domains(filter = nil)
			sdb = get_database_client
			pages = sdb.list_domains
			domains = []

			pages.each do |page|
				domains.concat(page.data.domain_names.select {|n| filter.nil? or n.start_with? filter})
			end

			return domains
		end

		def self.delete_items(domain_name, item_name)
			items = [*item_name] #coerce the thing into being an array. This is cool. And weird. But cool.
			domain_name = build_domain(domain_name)
			sdb = get_database_client

			#batch_delete_attributes can only delete up to 25 per call. Batching up tokens in groups of 25 is more trouble than it's worth right now. Optimization for later.
			items.each {|item| sdb.delete_attributes(domain_name: domain_name, item_name: item) }
		end

		def self.find_first_item_by_attribute(domain_name, attribute_name, attribute_value)
			sdb = get_database_client
			attribute_value = attribute_value.to_s 

			query = "select * from #{SDB.build_domain(domain_name)} where #{attribute_name} = '#{attribute_value}'"
			data = sdb.select(select_expression: query)
			item = nil

			data.each do |page|
				if page.items.count > 0
					item = page.items[0]
					break 
				end
			end

			return item
		end

		def self.expire_domain(domain)
			domain = build_domain(domain)
			now = Time.now.getutc.to_i
			query = "select itemName() from #{domain} where expires <= '#{now}'"

			items_to_delete = []
			data = get_database_client.select(select_expression: query)
			data.each do |page|
				items_to_delete.concat(page.data.items.map { |i| i.name })
			end

			delete_items(domain, items_to_delete)
		end
	end


	def self.create_xsrf_token(action_type = nil)
		token = SecureRandom.hex(26).to_s
		
		now = Time.now.getutc.to_i
		expires = now + (1 * 60 * 60) #expire in 1 hour

		attributes = [	{ name: "token", value: token, replace: true },
										{ name: "expires", value: expires.to_s, replace: true }]

		if not action_type.nil?
			attributes << { name: "action_type", value: action_type.to_s, replace: true }
		end

		sdb = SDB.get_database_client
		sdb.put_attributes(	domain_name: SDB.build_domain("xsrf_tokens"), item_name: token, attributes: attributes)

		return token
	end

	def self.validate_xsrf_token token, action_type = nil
		#clean up when validating just to keep the domain tidy
		cleanup_xsrf_tokens
		now = Time.now.getutc.to_i

		sdb = SDB.get_database_client
		query = "select token from #{SDB.build_domain('xsrf_tokens')} where token = '#{token}' and expires >= '#{now}' "
		query = query + " and action_type = '#{action_type}' " if not action_type.nil? 

		data = sdb.select(select_expression: query).data
		found = (data.items.count > 0)

		
		delete_xsrf_tokens token if found 
		return found
	end

	def self.cleanup_xsrf_tokens
		SDB.expire_domain('xsrf_tokens')
	end

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

		sdb = SDB.get_database_client
		query = "select user_id from #{SDB.build_domain("sessions")} where session_token = '#{session_token}' and expires >= '#{now}'"
		items = sdb.select(select_expression: query).data.items
		item = items.count > 0 ? items[0] : nil
		return nil if item.nil?
		
		user_id = SDB.find_attribute(item, "user_id")
		return nil if user_id.nil? 

		profile = find_user_profile_by_user_id(user_id)
		return profile
	end

	def self.cleanup_user_sessions
		SDB.expire_domain('sessions')
	end

	def self.init_amazon
		prefix = $config[:aws][:sdb][:domain_prefix]
		all_domains = SDB.list_domains prefix
		needed_domains = ["profiles", "meetings", "nominations", "sessions", "xsrf_tokens"].map {|d| prefix + d}
	 	

		sdb = SDB.get_database_client
		
		needed_domains.each do |n|
			if not all_domains.include? n
				sdb.create_domain domain_name: n
			end
		end
	end

	def self.find_user_profile_by_user_id user_id
		item = Database::SDB.find_first_item_by_attribute("profiles", "user_id", user_id)
		return build_profile_from_sdb_item(item)
	end

	def self.find_user_profile_by_facebook_id facebook_id 
		item = Database::SDB.find_first_item_by_attribute("profiles", "facebook_id", facebook_id)
		return build_profile_from_sdb_item(item)
	end

	def self.save_user_profile profile 
		profile.user_id = SecureRandom.hex(16) if (profile.user_id.nil? || profile.user_id == "")

		attributes = UserProfile.profile_properties.map do |p|
			value = profile.send(p).to_s
			{ name: p, value: value, replace: true}
		end

		SDB.get_database_client.put_attributes(	domain_name: SDB.build_domain("profiles"),
											item_name: profile.user_id,
											attributes: attributes)
	end

	def self.delete_user_profile profile 
		#take either a user_id or a profile object 
		user_id = profile.respond_to?('user_id') ? profile.user_id : profile
		SDB.delete_items("profiles", user_id)
	end

	def self.count_user_profiles
		query = "select count(*) from #{SDB.build_domain("profiles")}"
		data = SDB.get_database_client.select(select_expression: query)

		if data 
			return (data.items[0].attributes.select {|a| a.name = "Count"})[0].value.to_i
		end

		return 0
	end

	def self.list_user_profiles
		query = "select * from #{SDB.build_domain("profiles")}"
		data = SDB.get_database_client.select(select_expression: query)

		profiles = []
		data.each do |page|
			profiles.concat page.data.items.map {|i| build_profile_from_sdb_item i}
		end

		return profiles
	end

	def self.build_profile_from_sdb_item item
		return nil if item.nil? 

		profile = UserProfile.new

		UserProfile.profile_properties.each do |p|
			value = SDB.find_attribute(item, p).to_s
			method = p + "="
			profile.send(method, value)
		end

		return profile
	end
end





