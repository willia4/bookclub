require 'json'
require './apis/goodreads.rb'

get '/books/add' do 
  erb :book_add
end

post '/books/add' do

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