require 'securerandom'
require './database/database.rb'
require './database/redis.rb'
require './models/book.rb'

module Database
  module Books
    def self.save_book book
      if book.book_id.nil? || book.book_id == ""
        book.book_id = SecureRandom.hex(16)
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
      book = book.book_id if book.respond_to?("book_id")

      Redis.delete_book_id(book)
      SDB.delete_items('books', book)
    end

    def self.list_books
      return list_books_from_sdb_query("select * from #{SDB.build_domain("books")}")
    end

    def self.list_unread_books
      return list_books_from_sdb_query("select * from #{SDB.build_domain("books")} where read = 'false'")
    end

    def self.list_read_books
      return list_books_from_sdb_query("select * from #{SDB.build_domain("books")} where read = 'true'")
    end

    def self.find_book_by_book_id(book_id)
      book = Redis.find_book_by_book_id(book_id)
      return book if !book.nil?

      item = Database::SDB.find_first_item_by_attribute("books", "book_id", book_id)
      return nil if item.nil?

      book = build_book_from_sdb_item(item)
      Redis.store_book(book)
      return book
    end

    def self.list_books_from_sdb_query query
      data = SDB.select(query)

      books = []
      data.each do |page|
        books.concat(page.data.items.map { |i| build_book_from_sdb_item(i) })
      end

      return books
    end

    def self.build_book_from_sdb_item(item)
      return nil if item.nil?

      book = Models::Book.new
      Models::Book.sdb_properties.each do |p|
        value = SDB.find_attribute(item, p).to_s
        method = p + "="
        book.send(method, value)
      end

      return book
    end
  end  
end