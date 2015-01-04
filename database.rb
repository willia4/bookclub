require 'aws-sdk-core'
require 'securerandom'

module Database
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

	def self.create_xsrf_token(action_type = nil)
		token = SecureRandom.hex(26).to_s
		
		now = Time.now.getutc.to_i
		expires = now + (1 * 60 * 60) #expire in 1 hour

		attributes = [	{
							name: "token",
							value: token,
							replace: true
						},
						{ 	name: "expires",
							value: expires.to_s,
							replace: true
						}]

		if not action_type.nil?
			attributes << {name: "action_type",
						   value: action_type.to_s,
						   replace: true}
		end

		sdb = get_database_client
		sdb.put_attributes(	domain_name: build_domain("xsrf_tokens"),
							item_name: token,
							attributes: attributes
						)

		return token
	end

	def self.validate_xsrf_token token, action_type = nil
		#clean up when validating just to keep the domain tidy
		cleanup_xsrf_tokens
		now = Time.now.getutc.to_i

		sdb = get_database_client
		query = "select token from #{build_domain('xsrf_tokens')} where token = '#{token}' and expires >= '#{now}' "
		query = query + " and action_type = '#{action_type}' " if not action_type.nil? 

		data = sdb.select(select_expression: query).data
		found = (data.items.count > 0)

		
		delete_xsrf_tokens token if found 
		return found
	end

	def self.cleanup_xsrf_tokens
		sdb = get_database_client

		now = Time.now.getutc.to_i
		query = "select * from #{build_domain('xsrf_tokens')} where expires <= '#{now}'"

		tokens_to_delete = []

		data = sdb.select(select_expression: query)
		data.each do |page|
			tokens_to_delete.concat(page.data.items.map {|i| i.name })
		end

		delete_xsrf_tokens tokens_to_delete
	end

	def self.delete_xsrf_tokens tokens 
		tokens = [*tokens] #coerce the thing into being an array. This is cool. And weird. But cool.

		if tokens.count > 0
			get_database_client.batch_delete_attributes(domain_name: build_domain('xsrf_tokens'),
														items: tokens.map {|t| {name: t} })
		end
	end

	def self.build_domain(domain)
		prefix = $config[:aws][:sdb][:domain_prefix]
		return prefix + domain
	end

	def self.init_amazon
		prefix = $config[:aws][:sdb][:domain_prefix]
		all_domains = list_domains prefix
		needed_domains = ["profiles", "meetings", "nominations", "sessions", "xsrf_tokens"].map {|d| prefix + d}
	 	

		sdb = get_database_client
		
		needed_domains.each do |n|
			if not all_domains.include? n
				sdb.create_domain domain_name: n
			end
		end
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
end





