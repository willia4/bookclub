require 'aws-sdk-core'

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

	def self.init_amazon
		prefix = $config[:aws][:sdb][:domain_prefix]
		all_domains = list_domains prefix
		needed_domains = ["profiles", "meetings", "nominations", "sessions"].map {|d| prefix + d}
	 	

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





