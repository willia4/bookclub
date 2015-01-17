require 'securerandom'

require './database/sdb.rb'
require './database/s3.rb'
require './database/debug.rb'
require './database/xsrf_tokens.rb'
require './database/user_sessions.rb'
require './database/user_profile.rb'
require './database/books.rb'
require './database/meetings.rb'

module Database
	def self.init_amazon
		prefix = $config[:aws][:sdb][:domain_prefix]
		all_domains = SDB.list_domains prefix
		needed_domains = ["profiles", "meetings", "books", "votes", "sessions", "xsrf_tokens"].map {|d| prefix + d}
	 	
		sdb = SDB.get_database_client
		
		needed_domains.each do |n|
			if not all_domains.include? n
				sdb.create_domain domain_name: n
			end
		end
	end
end