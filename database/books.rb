require 'securerandom'
require './database/database.rb'

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

      SDB.get_database_client.put_attributes(domain_name: SDB.build_domain("books"), 
                                            item_name: book.book_id,
                                            attributes: attributes)
    end

    def self.delete_book book
      book = book.book_id if book.respond_to?("book_id")

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