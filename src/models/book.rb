require 'action_view' 
include ActionView::Helpers::DateHelper

module Models
  class Book
    def self.sdb_properties
      ["book_id", "title", "author", "summary_key", "image_url", "external_url", "read", "rejected", "date_added", "addedby_id"]
    end

    attr_accessor :book_id
    attr_accessor :title
    attr_accessor :author
    attr_accessor :summary_key
    attr_accessor :summary
    attr_writer :image_url
    attr_accessor :external_url
    attr_accessor :read
    attr_accessor :rejected
    attr_accessor :addedby_id

    #these are not filled in when loading a book but are there for the convenience of other methods
    attr_accessor :votes
    attr_accessor :user_vote

    def initialize(request)
      @scheme = request.scheme
      @date_added = Time.now
    end

    def read=(read)
      @read = ((read == "true") || (read == "yes") || (read == true))

      @rejected = false if @read
    end

    def read
      @read ? "true" : "false"
    end

    def rejected=(rejected)
      @rejected = ((rejected == "true") || (rejected == "yes") || (rejected == true))

      @read = false if @rejected
    end

    def rejected
      @rejected ? "true" : "false"
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

    def image_url
      Database::S3.fixup_s3_url_for_https(@scheme, @image_url)
    end

    def book_url(request)
      URI($config.make_url(request, "/books/book/#{self.book_id}"))
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

    def self.from_json(request, json_string)
      r = Book.new(request)
      h = JSON.parse(json_string)

      defaults = {"rejected" => "false", "addedby_id" => ""}

      Book.sdb_properties.each do |p|
        if not h.keys.include?(p)
          raise "Invalid JSON for Modules::Book" if not defaults.keys.include?(p)
          value = defaults[p]
        else
          value = h[p]
        end

        method_name = p + "="
        
        r.send(method_name, value)
      end

      r.summary = h["summary"]
      return r
    end
  end
end