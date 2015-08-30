require 'securerandom'
require './database/database.rb'
require './database/redis.rb'
require './database/s3.rb'
require './models/book.rb'

module Database
  module Books
    def self.save_book book
      if book.book_id.nil? || book.book_id == ""
        book.book_id = SecureRandom.hex(16)
      end

      #SDB has a max of 1024 characters for attribute values. A good summary can be significantly longer than that,
      #so we need to store it somewhere else instead. S3 will do. So we will store a key in SDB and that key will
      #bring back a text/plain object from S3.
      #if we are re-saving a book and the summary changed, we will want to update that in S3. The easiest way to do
      #that is just to delete the old key and create a new one
      needsNewSummaryKey = false
      if book.summary.nil? || book.summary == ""
        book.summary_key = ""
      else
        if book.summary_key.nil? || book.summary_key == ""
          needsNewSummaryKey = true
        else
          existing_summary = S3.get_string_value(book.summary_key)
          needsNewSummaryKey = (existing_summary != book.summary)
        end
      end

      if needsNewSummaryKey
        if !book.summary_key.nil? && book.summary_key != ""
          S3.delete_string_value(book.summary_key)
        end

        book.summary_key = S3.upload_string_value(book.summary)
      end

      attributes = Models::Book.sdb_properties.map do |p|
        value = book.send(p).to_s
        {name: p, value: value, replace: true}
      end

      Redis.delete_book_id(book.book_id)
      SDB.get_database_client.put_attributes(domain_name: SDB.build_domain("books"), 
                                            item_name: book.book_id,
                                            attributes: attributes)
    end

    def self.delete_book book
      Redis.delete_book_id(book.book_id)
      SDB.delete_items('books', book.book_id)

      if !book.summary_key.nil? && book.summary_key != ""
        S3.delete_string_value(book.summary_key)
      end
    end

    def self.list_books(request)
      return list_books_from_sdb_query(request, "select * from #{SDB.build_domain("books")}")
    end

    def self.list_unread_books(request)
      return list_books_from_sdb_query(request, "select * from #{SDB.build_domain("books")} where read = 'false' and (rejected is null or rejected = 'false') ")
    end

    def self.list_rejected_books(request)
      return list_books_from_sdb_query(request, "select * from #{SDB.build_domain("books")} where rejected = 'true'")
    end

    def self.list_read_books(request)
      return list_books_from_sdb_query(request, "select * from #{SDB.build_domain("books")} where read = 'true'")
    end

    def self.find_book_by_book_id(request, book_id)
      book = Redis.find_book_by_book_id(request, book_id)
      return book if !book.nil?

      item = Database::SDB.find_first_item_by_attribute("books", "book_id", book_id)
      return nil if item.nil?

      book = build_book_from_sdb_item(request, item)
      Redis.store_book(book)
      return book
    end

    def self.list_books_from_sdb_query(request, query)
      data = SDB.select(query)

      books = []
      data.each do |page|
        books.concat(page.data.items.map { |i| build_book_from_sdb_item(request, i) })
      end

      books.each { |b| Redis.store_book(b) }
      return books
    end

    def self.build_book_from_sdb_item(request, item)
      return nil if item.nil?

      book = Models::Book.new(request)
      Models::Book.sdb_properties.each do |p|
        value = SDB.find_attribute(item, p).to_s
        method = p + "="
        book.send(method, value)
      end

      if book.summary_key.nil? || book.summary_key == ""
        book.summary = ""
      else
        book.summary = S3.get_string_value(book.summary_key) || ""
      end

      return book
    end
  end  
end