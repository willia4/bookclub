require './database/sdb.rb'
require './database/redis.rb'

module Database
  module Debug
    def self.delete_all_sessions
      sessions = list_all_sessions
      Database::SDB.delete_items('sessions', sessions.map { |s| s[:session_token] })
      Database::Redis.delete_all_sessions
    end

    def self.list_all_sessions
      query = "select * from #{Database::SDB.build_domain("sessions")}"
      data = Database::SDB.select(query)
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
      data = Database::SDB.select(query)
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

    def self.delete_all_user_profiles(request)
      profiles = Database::UserProfiles.list_user_profiles(request)
      Database::SDB.delete_items('profiles', profiles.map { |p| p.user_id })
    end

    def self.delete_all_books(request)
      books = Database::Books.list_books(request)
      Redis.delete_all_books
      Database::SDB.delete_items('books', books.map { |b| b.book_id })
    end

    def self.delete_all_meetings
      meetings = Database::Meetings.list_meetings
      Database::SDB.delete_items('meetings', meetings.map { |m| m.meeting_id })
    end

    def self.delete_all_votes
      data = Database::SDB.select("select * from #{SDB.build_domain("votes")}")
      keys = []
      data.each do |page|
        keys.concat(page.data.items.map {|i| i.name })
      end
      Database::SDB.delete_items('votes', keys)
    end

    def self.list_all_votes
      data = Database::SDB.select("select * from #{SDB.build_domain("votes")}")
      votes = []
      data.each do |page|
        votes.concat(page.data.items.map do |i|
            {
              :itemName => i.name,
              :meeting_id => SDB.find_attribute(i, "meeting_id"),
              :book_id => SDB.find_attribute(i, "book_id"),
              :user_profile_id => SDB.find_attribute(i, "user_profile_id"),
              :vote => SDB.find_attribute(i, "vote").to_i
            }
        end)
      end
      return votes
    end
  end
end