require 'aws-sdk-core'

module Database
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

    def self.select(query)
      return get_database_client.select(select_expression: query, consistent_read: true)
    end

    def self.find_attribute(attributes, key)
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
      data = select(query)
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
      data = select(query)
      data.each do |page|
        items_to_delete.concat(page.data.items.map { |i| i.name })
      end

      delete_items(domain, items_to_delete)
    end
  end
end