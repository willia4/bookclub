require 'securerandom'
require './database/database.rb'
require './models/meeting.rb'

module Database
  module Meetings
    def self.save_meeting(meeting)
      SDB.save_simple_model("meetings", meeting, "meeting_id", Models::Meeting.sdb_properties)
    end

    def self.delete_meeting(meeting_id)
      Database::SDB.delete_items('meetings', [meeting_id])
    end

    def self.list_meetings
      return list_meetings_from_query("select * from #{SDB.build_domain("meetings")}")
    end

    def self.list_future_meetings
      return list_meetings.select {|m| m.date >= Date.today}
    end

    def self.list_meetings_from_query(query)
      data = SDB.select(query)
      meetings = []

      data.each do |page|
        meetings.concat(page.data.items.map do |i|
          meeting = Models::Meeting.new
          SDB.load_simple_model(meeting, i, "meeting_id", Models::Meeting.sdb_properties)
        end)
      end

      return meetings
    end

    def self.find_meeting_by_meeting_id(meeting_id)
      item = SDB.find_first_item_by_attribute("meetings", "meeting_id", meeting_id)
      return nil if item.nil?

      meeting = Models::Meeting.new
      SDB.load_simple_model(meeting, item, "meeting_id", Models::Meeting.sdb_properties)
      return meeting
    end

    def self.find_votes_for_meeting(meeting_id)
      votes = Redis.find_votes_for_meeting(meeting_id)
      return votes if !votes.nil?

      query = "select * from #{SDB.build_domain("votes")} where meeting_id = '#{meeting_id}'"
      data = SDB.select(query)

      votes = []
      data.each do |page|
        votes.concat(page.data.items.map do |i|
          {
            :meeting_id => meeting_id,
            :book_id => SDB.find_attribute(i, "book_id"),
            :user_profile_id => SDB.find_attribute(i, "user_profile_id"),
            :vote => SDB.find_attribute(i, "vote").to_i
          }
        end)
      end

      Redis.store_votes_for_meeting(meeting_id, votes)
      return votes
    end

    def self.record_vote_for_meeting(meeting_id, book_id, user_profile_id, vote)
      item_name = "#{meeting_id}:#{book_id}:#{user_profile_id}"
      attributes = [  {name: "meeting_id", value: meeting_id, replace: true},
                      {name: "book_id", value: book_id, replace: true},
                      {name: "user_profile_id", value: user_profile_id, replace: true},
                      {name: "vote", value: vote.to_s, replace: true}]

      Redis.delete_votes_for_meeting(meeting_id)
      SDB.get_database_client.put_attributes(domain_name: SDB.build_domain("votes"), item_name: item_name, attributes: attributes)
    end
  end
end