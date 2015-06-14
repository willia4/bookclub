require 'json'

module Models
  class Meeting
    def self.sdb_properties
      ["meeting_id", "date_storage", "time", "location", "selected_book_id", "nominated_book_ids_storage"]
    end

    attr_accessor :meeting_id
    attr_accessor :date
    attr_accessor :time #time is a free-form text field to allow for things like "5:30is"; it's only for display
    attr_accessor :location 
    attr_accessor :selected_book_id
    attr_accessor :nominated_book_ids

    #store date internally as a Date but treat it as a string for the outside world
    #this seems like the sanest way to deal with SDB's "everything is a string" mentality
    def date_storage=(date_storage)
      begin
        @date = Date.parse(date_storage)
      rescue 
        @date = nil
      end
    end

    def date_storage 
      begin
        return @date.to_s
      rescue
        return ""
      end
    end

    def nominated_book_ids_storage=(nominated_book_ids_storage)
      begin
        @nominated_book_ids = JSON.parse(nominated_book_ids_storage)
      rescue
        @nominated_book_ids = []
      end
    end

    def nominated_book_ids_storage
      begin
        return JSON.pretty_generate(@nominated_book_ids)
      rescue
        return ""
      end
    end

    def <=> other
      return self.date <=> other.date
    end

    def initialize
      @nominated_book_ids = []
    end
  end
end