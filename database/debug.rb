require './database/sdb.rb'

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

    def self.list_all_xsrf_tokens
      query = "select * from #{Database::SDB.build_domain("xsrf_tokens")}"
      data = Database::SDB.get_database_client.select(select_expression: query)
      tokens = []
      data.each do |page|
        tokens.concat(page.data.items.map do |item|
          {
            xsrf_token: Database::SDB.find_attribute(item, "token"),
            expires: Database::SDB.find_attribute(item, "expires"),
            action_type: Database::SDB.find_attribute(item, "action_type")
          }
        end)
      end
      tokens
    end

    def self.delete_all_profiles
      profiles = Database::UserProfiles.list_user_profiles
      Database::SDB.delete_items('profiles', profiles.map { |p| p.user_id })
    end
  end
end