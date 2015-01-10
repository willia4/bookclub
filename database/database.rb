require 'securerandom'

require './database/sdb.rb'
require './database/debug.rb'
require './database/xsrf_tokens.rb'
require './database/user_sessions.rb'
require './database/user_profile.rb'

module Database
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
end