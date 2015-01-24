require 'action_view' 
include ActionView::Helpers::DateHelper

module Models
  class Book
    def self.sdb_properties
      ["book_id", "title", "author", "summary_key", "image_url", "external_url", "read", "date_added"]
    end

    attr_accessor :book_id
    attr_accessor :title
    attr_accessor :author
    attr_accessor :summary_key
    attr_accessor :summary
    attr_accessor :image_url
    attr_accessor :external_url
    attr_accessor :read

    #these are not filled in when loading a book but are there for the convenience of other methods
    attr_accessor :votes
    attr_accessor :user_vote

    def read=(read)
      @read = ((read == "true") || (read == "yes") || (read == true))
    end

    def read
      @read ? "true" : "false"
    end

    #store date_added as a Time but treat it as a string for the outside world
    #this is my best attempt to deal with the way that SDB thinks everything is a string
    def date_added=(date_added)
      @date_added = Time.parse(date_added)
    end

    def date_added
      @date_added.getutc.to_s
    end

    def age
      time_ago_in_words(@date_added)
    end

    def book_url
      base = $config[:general][:base_url]
      URI.join(base, "/books/book/#{self.book_id}")
    end

    def initialize
      @date_added = Time.now
    end

    def == other
      return self.book_id == other.book_id
    end

    def <=> other
      if self.title != other.title
        return self.title <=> other.title
      else
        return self.author <=> other.author
      end
    end

    def to_json
      h = {}
      Book.sdb_properties.each do |p|
        h[p] = self.send(p)
      end

      h["summary"] = self.summary
      h.to_json
    end

    def self.from_json(json_string)
      r = Book.new
      h = JSON.parse(json_string)

      Book.sdb_properties.each do |p|
        raise "Invalid JSON for Modules::Book" if not h.keys.include?(p)

        method_name = p + "="
        
        r.send(method_name, h[p])
      end

      r.summary = h["summary"]
      return r
    end
  end
end