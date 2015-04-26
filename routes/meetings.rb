require 'sanitize'
require 'date'
require './database/database.rb'
require './models/meeting.rb'
require './exceptions/AppError.rb'
require './exceptions/NotFoundError.rb'

def get_nominated_books_for_meeting(meeting)
  return [] if !meeting.selected_book_id.nil? && meeting.selected_book_id != ""

  votes = Database::Meetings.find_votes_for_meeting(meeting.meeting_id)

  nominated_books = meeting.nominated_book_ids.map do |bid|
    book = Database::Books.find_book_by_book_id(bid)
    book_votes = votes.select { |v| v["book_id"] == bid }
    
    book.votes = book_votes.reduce(0) { |total, v| total + v["vote"] }
    book.user_vote = book_votes.select { |v| v["user_profile_id"] == @session_state[:user_profile].user_id }
                        .map { |v| v["vote"] }
                        .first

    book.user_vote = book.user_vote.nil? ? 0 : book.user_vote.to_i

    book
  end

  nominated_books = nominated_books.sort do |a,b|
    if a.votes != b.votes
      a.votes <=> b.votes
    else
      Time.parse(a.date_added) <=> Time.parse(b.date_added)
    end
  end

  #sort the books in descending order
  nominated_books.reverse! 

  return nominated_books
end

def get_json_nominated_books_for_meeting(meeting)
  nominated_books = get_nominated_books_for_meeting(meeting)

  nominated_books = nominated_books.map do |b|
    date_added = Time.parse(b.date_added).getlocal
    today = Time.now.getlocal

    age =  (date_added.year == today.year && date_added.month == today.month && date_added.day == today.day) ? "today" : (b.age + " ago")

    {
      :book_id => b.book_id,
      :votes => b.votes,
      :user_vote => b.user_vote,
      :image_url => b.image_url,
      :title => b.title,
      :author => b.author,
      :book_url => b.book_url,
      :date_added => date_added,
      :date_added_formatted => date_added.strftime("%Y-%b-%d @ %I:%M%P %Z"),
      :age_statement => age,
      :upvoted => (b.user_vote > 0),
      :downvoted => (b.user_vote < 0)
    }
  end

  JSON.generate({:nominated_books => nominated_books})   
end

[:get, :post, :put].each do |method|
  ['/meetings/add', '/meetings/meeting/:id/edit', '/meetings/meeting/:meeting_id/books/:book_id'].each do |route|
    send method, route do
      pass if @session_state[:user_profile].user_status == 'admin'

      raise AuthorizationError.new("access admin area", "Only administrators may access admin functionality")
    end
  end
end

get '/meetings' do
  @page_state[:page_title] = "Meetings"
  meetings = Database::Meetings.list_meetings

  meetings = meetings.map do |m|
    b = m.selected_book_id.nil? ? nil : Database::Books.find_book_by_book_id(m.selected_book_id)
    nominations = nil

    if !b
      nominations = m.nominated_book_ids.map {|book_id| Database::Books.find_book_by_book_id(book_id) }
      nominations = nominations.map {|b| {:title => b.title, :cover => b.image_url} }
    end

    {
      :date => m.date,
      :time => m.time,
      :location => m.location,
      :url => "/meetings/meeting/" + m.meeting_id,

      :selected_book => b.nil? ? nil : b.title,
      :selected_book_cover => b.nil? ? nil : b.image_url,

      :nominations => nominations
    }
  end

  today = Date.today
  @past_meetings = meetings
                    .select { |m| m[:date] < today } 
                    .sort { |a,b| a[:date] <=> b[:date] }
                    

  @future_meetings = meetings
                      .select { |m| m[:date] >= today } 
                      .sort { |a,b| a[:date] <=> b[:date] } 
                      .reverse

  erb :meetings
end

get '/meetings/add' do
  @page_state[:page_title] = "Add a meeting"
  erb :meeting_add
end

post '/meetings/add' do
  date = Sanitize.fragment(params[:meeting_date], Sanitize::Config::RESTRICTED)
  time = Sanitize.fragment(params[:meeting_time], Sanitize::Config::RESTRICTED)
  location = Sanitize.fragment(params[:meeting_location], Sanitize::Config::RESTRICTED)
  add_random_nominations = (params[:add_random_nominations] == "true")

  begin
    date = Date.parse(date)
  rescue ArgumentError
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "meeting_date", "message" => "Unable to parse meeting date as a date"})
  end

  newMeeting = Models::Meeting.new
  newMeeting.date = date.to_s
  newMeeting.time = time
  newMeeting.location = location
  
  if add_random_nominations
    books = Database::Books.list_unread_books
    books = books.sample(5)
    newMeeting.nominated_book_ids = books.map { |b| b.book_id }
  end

  Database::Meetings.save_meeting(newMeeting)

  status 200 
  content_type :json, 'charset' => 'utf-8'
  base_url = $config[:general][:base_url]
  meeting_url = URI.join(base_url, "/meetings/meeting/#{newMeeting.meeting_id}").to_s

  JSON.pretty_generate({"meeting_id" => newMeeting.meeting_id, "meeting_url" => meeting_url, "redirect_url" => meeting_url})   
end

get '/meetings/meeting/:id' do |id|
  @meeting = Database::Meetings.find_meeting_by_meeting_id id
  raise NotFoundError.new("load the requested meeting", "The meeting could not be found") if @meeting.nil?

  @page_state[:page_title] = "#{@meeting.date} Meeting"

  if @meeting.selected_book_id.nil? || @meeting.selected_book_id == "" 
    @selected_book = nil
    @initial_state_json = get_json_nominated_books_for_meeting(@meeting).gsub("'", %q(\\\')) # http://stackoverflow.com/questions/10551982/replace-single-quote-with-backslash-single-quote
  else
    @selected_book = Database::Books.find_book_by_book_id(@meeting.selected_book_id)
    @initial_state_json = '{}';
  end

  erb :meeting
end

post '/meetings/meeting/:id/edit' do |id|
  meeting = Database::Meetings.find_meeting_by_meeting_id id
  raise NotFoundError.new("edit the requested meeting", "The meeting could not be found") if meeting.nil?

  date = Sanitize.fragment(params[:meeting_date], Sanitize::Config::RESTRICTED)
  time = Sanitize.fragment(params[:meeting_time], Sanitize::Config::RESTRICTED)
  location = Sanitize.fragment(params[:meeting_location], Sanitize::Config::RESTRICTED)

  begin
    date = Date.parse(date)
  rescue ArgumentError
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "meeting_date", "message" => "Unable to parse meeting date as a date"})
  end

  meeting.date = date.to_s
  meeting.time = time
  meeting.location = location

  Database::Meetings.save_meeting(meeting)
  status 200
  content_type :json, 'charset' => 'utf-8'
  "{}"
end

get '/meetings/meeting/:meeting_id/other_unread' do |meeting_id|
  meeting = Database::Meetings.find_meeting_by_meeting_id meeting_id
  raise NotFoundError.new("edit the requested meeting", "The meeting could not be found") if meeting.nil?

  my_books = get_nominated_books_for_meeting(meeting)
  books = Database::Books.list_unread_books

  books = books
            .sort
            .select { |b| !my_books.include?(b) }
            .map do |b|
              {
                "book_id" => b.book_id,
                "title" => b.title,
                "author" => b.author,
                "image_url" => b.image_url
              }
            end

  content_type :json, 'charset' => 'utf-8'
  JSON.pretty_generate({:books => books})
end

get '/meetings/meeting/:meeting_id/books' do |meeting_id|
  meeting = Database::Meetings.find_meeting_by_meeting_id(meeting_id)
  raise NotFoundError.new("listing meeting books", "the meeting could not be found") if meeting.nil?
  raise NotFoundError.new("listing meeting books", "the meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeeting.selected_book_id != "")

  status 200 
  content_type :json, 'charset' => 'utf-8'
  
  get_json_nominated_books_for_meeting(meeting)
end

post '/meetings/meeting/:meeting_id/books/:book_id/vote/:direction' do |meeting_id, book_id, direction|
  raise AppError.new("voting", "invalid voting direction", 400) if direction != "up" && direction != "down" && direction != "novote"
  
  meeting = Database::Meetings.find_meeting_by_meeting_id(meeting_id)
  raise NotFoundError.new("voting", "the meeting could not be found") if meeting.nil?
  raise AppError.new("voting", "this meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeting.selected_book_id != "")
  raise NotFoundError.new("voting", "the book is not nominated for this meeting") if (meeting.nominated_book_ids.find { |bid| bid == book_id}).nil?

  user_profile_id = @session_state[:user_profile].user_id
  current_votes = Database::Meetings.find_votes_for_meeting(meeting_id) 
  current_votes = current_votes.select { |v| v["book_id"] == book_id && v["user_profile_id"] == user_profile_id}
  current_vote = current_votes.size > 0 ? current_votes[0]["vote"] : 0

  #redit style voting: 
  #if we are voting up and have already voted up, reset the vote to zero 
  #if we are voting up and have not already voted up, set the vote to 1
  #if we are voting down and have already voted down, reset the vote to zero
  #if we are voting down and have not already voted down, set the vote to -1
  if direction == "up" && current_vote > 0 
    vote = 0
  elsif direction == "up" && current_vote <= 0
    vote = 1
  elsif direction == "down" && current_vote < 0
    vote = 0
  elsif direction =="down" && current_vote >= 0
    vote = -1
  else
    raise AppError.new("voting", "invalid voting logic detected - this is a bug; please report it", 500)
  end

  Database::Meetings.record_vote_for_meeting(meeting_id, book_id, user_profile_id, vote)

  status 200 
  content_type :json, 'charset' => 'utf-8'
  
  get_json_nominated_books_for_meeting(meeting)
end

put '/meetings/meeting/:meeting_id/books/:book_id' do |meeting_id, book_id|
    meeting = Database::Meetings.find_meeting_by_meeting_id(meeting_id)
    raise NotFoundError.new("adding a book to a meeting", "the meeting could not be found") if meeting.nil?
    raise NotFoundError.new("adding a book to a meeting", "the meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeting.selected_book_id != "")

    book = Database::Books.find_book_by_book_id(book_id)
    raise NotFoundError.new("adding a book to a meeting", "the book could not be found") if book.nil?

    raise AppError.new("adding a book to a meeting", "this meeting already has this book") if meeting.nominated_book_ids.include?(book_id)

    meeting.nominated_book_ids << book_id
    Database::Meetings.save_meeting(meeting)

    status 200
    content_type :json, 'charset' => 'utf-8'
    "{}"
end

delete '/meetings/meeting/:meeting_id/books/:book_id' do |meeting_id, book_id|
  raise AuthorizationError.new("reject book from meeting", "Only administrators may reject books from a meeting") if @session_state[:user_profile].user_status != 'admin'

  meeting = Database::Meetings.find_meeting_by_meeting_id(meeting_id)
  raise NotFoundError.new("rejecting book", "the meeting could not be found") if meeting.nil?
  raise AppError.new("rejecting book", "this meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeting.selected_book_id != "")
  raise NotFoundError.new("rejecting book", "the book is not nominated for this meeting") if (meeting.nominated_book_ids.find { |bid| bid == book_id}).nil?

  Database::Meetings.delete_votes_for_meeting_and_book(meeting_id, book_id)  
  meeting.nominated_book_ids = meeting.nominated_book_ids.select {|n| n != book_id }
  Database::Meetings.save_meeting(meeting)

  status 200
  content_type :json, 'charset' => 'utf-8'
  get_json_nominated_books_for_meeting(meeting)
end

get '/meetings/meeting/:meeting_id/books/:book_id/select' do |meeting_id, book_id|
  raise AuthorizationError.new("selecting book", "Only administrators may select books for a meeting") if @session_state[:user_profile].user_status != 'admin'

  meeting = Database::Meetings.find_meeting_by_meeting_id(meeting_id)
  raise NotFoundError.new("selecting book", "the meeting could not be found") if meeting.nil?
  raise AppError.new("selecting book", "this meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeting.selected_book_id != "")
  raise NotFoundError.new("selecting book", "the book is not nominated for this meeting") if (meeting.nominated_book_ids.find { |bid| bid == book_id}).nil?

  book = Database::Books.find_book_by_book_id(book_id)
  raise NotFoundError.new("selecting book", "the book could not be found") if book.nil?

  meeting.selected_book_id = book.book_id
  meeting.nominated_book_ids = []

  Database::Meetings.delete_votes_for_meeting(meeting_id)
  Database::Meetings.save_meeting(meeting)

  book.read = true 
  Database::Books.save_book(book)
  
  status 200
  "{}"
end