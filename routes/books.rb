require 'json'
require 'sanitize'
require './apis/goodreads.rb'
require './database/database.rb'
require './models/book.rb'
require './exceptions/AppError.rb'

get '/books/add' do 
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