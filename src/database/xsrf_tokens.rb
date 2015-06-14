require 'securerandom'
require './database/sdb.rb'

module Database
  module XSRFTokens
      def self.create_xsrf_token(action_type = nil)
        token = SecureRandom.hex(26).to_s
        
        now = Time.now.getutc.to_i
        expires = now + (1 * 60 * 60) #expire in 1 hour

        attributes = [  { name: "token", value: token, replace: true },
                        { name: "expires", value: expires.to_s, replace: true }]

        if not action_type.nil?
          attributes << { name: "action_type", value: action_type.to_s, replace: true }
        end

        sdb = SDB.get_database_client
        sdb.put_attributes( domain_name: SDB.build_domain("xsrf_tokens"), item_name: token, attributes: attributes)

        return token
      end

      def self.validate_xsrf_token token, action_type = nil
        #clean up when validating just to keep the domain tidy
        cleanup_xsrf_tokens
        now = Time.now.getutc.to_i

        query = "select token from #{SDB.build_domain('xsrf_tokens')} where token = '#{token}' and expires >= '#{now}' "
        query = query + " and action_type = '#{action_type}' " if not action_type.nil? 

        data = SDB.select(query).data
        found = (data.items.count > 0)

        SDB.delete_items('xsrf_tokens', token) if found
        return found
      end

      def self.cleanup_xsrf_tokens
        SDB.expire_domain('xsrf_tokens')
      end
  end
end