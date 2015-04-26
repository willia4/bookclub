require 'json'
require 'sanitize'
require './apis/goodreads.rb'
require './database/database.rb'
require './models/book.rb'
require './exceptions/AppError.rb'

get '/books' do
  erb :books
end

get '/books/add' do 
  @page_state[:page_title] = "Nominate a book"
  erb :book_add
end

post '/books/add' do
  title = Sanitize.fragment(params[:title], Sanitize::Config::RELAXED)
  author = Sanitize.fragment(params[:author], Sanitize::Config::RELAXED)
  external_url = Sanitize.fragment(params[:external_url], Sanitize::Config::RELAXED)
  image_url = Sanitize.fragment(params[:image_url], Sanitize::Config::RELAXED)
  summary = Sanitize.fragment(params[:summary], Sanitize::Config::RELAXED)

  if title.nil? || title == ""
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "title", "message" => "Title is required."})
  end

  if author.nil? || author == ""
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "author", "message" => "Author is required."})
  end

  if !external_url.nil? && !external_url.empty?
    uri = URI.parse(external_url)
    if !uri.kind_of?(URI::HTTP)  && !uri.kind_of?(URI::HTTPS)
      status 400
      content_type :json, 'charset' => 'utf-8'
      return JSON.pretty_generate({"field" => "external_url", "message" => "The additional URL must be a valid HTTP or HTTPS URL."})
    end
  end

  if !image_url.nil? && !image_url.empty?
    uri = URI.parse(image_url)
    if !uri.kind_of?(URI::HTTP)  && !uri.kind_of?(URI::HTTPS)
      status 400
      content_type :json, 'charset' => 'utf-8'
      return JSON.pretty_generate({"field" => "image_url", "message" => "The image URL must be a valid HTTP or HTTPS URL."})
    end
  end

  book = Models::Book.new
  book.title = title 
  book.author = author
  book.external_url = external_url
  book.summary = summary 
  book.addedby_id = @session_state[:user_profile].user_id

  if !image_url.nil? && !image_url.empty? 
    book.image_url = Database::S3.upload_url(image_url)
  end

  Database::Books.save_book(book)

  status 200
  content_type :json, 'charset' => 'utf-8'
  base_url = $config[:general][:base_url]
  book_url = URI.join(base_url, "/books/book/#{book.book_id}").to_s

  JSON.pretty_generate({"book_id" => book.book_id, "book_url" => book_url, "redirect_url" => base_url})   
end

get '/books/book/:book_id' do |book_id|
  @book = Database::Books.find_book_by_book_id(book_id)
  @page_state[:page_title] = @book.title

  raise NotFoundError.new("load the requested book", "The book could not be found") if @book.nil?

  erb :book
end

get '/books/search' do
  query = params[:query]
  results = []

  if !query.nil? && !query.empty?
    results = APIs::Goodreads.search(query)
  end

  content_type :json, 'charset' => 'utf-8'
  data = {:results => results}

  JSON.pretty_generate(data)
end

get '/books/goodreads/info/:id' do |id|
  halt(404) if id.nil? || id == ""

  data = APIs::Goodreads.lookup_book(id)

  content_type :json, 'charset' => 'utf-8'
  JSON.pretty_generate(data)
end

def map_books_to_json_hash(books)
  books.map do |book|
    date_added = Time.parse(book.date_added).getlocal
    today = Time.now.getlocal

    age =  (date_added.year == today.year && date_added.month == today.month && date_added.day == today.day) ? "today" : (book.age + " ago")

    {
      "book_id" => book.book_id,
      "book_url" => book.book_url,
      "title" => book.title,
      "author" => book.author,
      "image_url" => book.image_url,
      "addedby_id" => book.addedby_id,
      "date_added" => date_added,
      "date_added_formatted" => date_added.strftime("%Y-%b-%d @ %I:%M%P %Z"),
      "age_statement" => age,
    }
  end
end

get '/books/unread.json' do 
  content_type :json, 'charset' => 'utf-8'

  JSON.pretty_generate(map_books_to_json_hash(Database::Books.list_unread_books()))
end

get '/books/read.json' do
  content_type :json, 'charset' => 'utf-8'

  JSON.pretty_generate(map_books_to_json_hash(Database::Books.list_read_books()))
end

get '/books/rejected.json' do
  content_type :json, 'charset' => 'utf-8'

  JSON.pretty_generate(map_books_to_json_hash(Database::Books.list_rejected_books()))
end

post '/books/book/:book_id/reject' do |book_id|
  errorAction = "reject book from future consideration"

  book = Database::Books.find_book_by_book_id(book_id)
  raise NotFoundError.new(errorAction, "The book could not be found") if book.nil?

  user = @session_state[:user_profile]
  authorized = (user.user_status == "admin" || user.user_id == book.addedby_id)

  raise AuthorizationError.new(errorAction, "Only administrators or the original submitter may reject books from future consideration") if not authorized

  raise AppError.new(errorAction, "This book has already been selected for a meeting", 400) if book.read == "true"
  raise AppError.new(errorAction, "This book has already been rejected", 400) if book.rejected == "true"

  meetings = Database::Meetings.find_meetings_for_book(book_id)
  raise AppError.new(errorAction, "This book is nominated for #{meetings.size} meeting(s) and cannot be rejected.", 400) if meetings.size > 0

  book.rejected = true
  Database::Books.save_book(book)

  status 200
  content_type :json, 'charset' => 'utf-8'

  JSON.pretty_generate(map_books_to_json_hash(Database::Books.list_unread_books()))
end

post '/books/book/:book_id/unreject' do |book_id|
  errorAction = "un-reject book back to future consideration"

  book = Database::Books.find_book_by_book_id(book_id)
  raise NotFoundError.new(errorAction, "The book could not be found") if book.nil?

  user = @session_state[:user_profile]
  authorized = (user.user_status == "admin" || user.user_id == book.addedby_id)

  raise AuthorizationError.new(errorAction, "Only administrators or the original submitter may un-reject books") if not authorized

  raise AppError.new(errorAction, "This book has already been selected for a meeting", 400) if book.read == "true"
  raise AppError.new(errorAction, "This book has not been rejected", 400) if book.rejected == "false"

  book.rejected = false
  Database::Books.save_book(book)
  
  status 200
  content_type :json, 'charset' => 'utf-8'

  JSON.pretty_generate(map_books_to_json_hash(Database::Books.list_rejected_books()))
end