require 'sanitize'
require 'date'
require './database/database.rb'
require './models/meeting.rb'
require './exceptions/NotFoundError.rb'

[:get, :post].each do |method|
  send method, '/meetings/add' do
    pass if @session_state[:user_profile].user_status == 'admin'

    raise AuthorizationError.new("access admin area", "Only administrators may access admin functionality")
  end
end

get '/meetings/add' do
  erb :meeting_add
end

post '/meetings/add' do
  date = Sanitize.fragment(params[:meeting_date], Sanitize::Config::RELAXED)
  time = Sanitize.fragment(params[:meeting_time], Sanitize::Config::RELAXED)
  location = Sanitize.fragment(params[:meeting_location], Sanitize::Config::RELAXED)

  begin
    date = Date.parse(date)
  rescue ArgumentError
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "meeting_date", "message" => "Unable to parse meeting date as a date"})
  end

  #todo past meetings would be nice but it would be useless until I have a way to pick a book directly
  if date < Date.today
    status 400
    content_type :json, 'charset' => 'utf-8'
    return JSON.pretty_generate({"field" => "meeting_date", "message" => "Cannot add past meetings"})
  end

  known_meetings = Database::Meetings.list_meetings

  #todo make this optional
  books = Database::Books.list_unread_books
  books = books.sample(5)

  newMeeting = Models::Meeting.new
  newMeeting.date = date.to_s
  newMeeting.time = time
  newMeeting.location = location
  newMeeting.nominated_book_ids = books.map { |b| b.book_id }

  Database::Meetings.save_meeting(newMeeting)

  status 200 
  content_type :json, 'charset' => 'utf-8'
  base_url = $config[:general][:base_url]
  meeting_url = URI.join(base_url, "/meetings/meeting/#{newMeeting.meeting_id}").to_s

  JSON.pretty_generate({"meeting_id" => newMeeting.meeting_id, "meeting_url" => meeting_url, "redirect_url" => meeting_url})   
end

get '/meetings/meeting/:id' do |id|
  @meeting = Database::Meetings.find_meeting_by_meeting_id id
  raise NotFoundError.new "load the requested meeting", "The meeting could not be found" if @meeting.nil?

  if @meeting.selected_book_id.nil? || @meeting.selected_book_id == "" 
    @votes = Database::Meetings.find_votes_for_meeting(id)

    @nominated_books = @meeting.nominated_book_ids.map do |bid|
      book = Database::Books.find_book_by_book_id(bid)
      book_votes = @votes.select { |v| v[:book_id] == bid }
      
      book.votes = book_votes.reduce(0) { |total, v| total + v[:vote] }
      book.user_vote = book_votes.select { |v| v[:user_profile_id] == @session_state[:user_profile].user_id }
      book.user_vote = book.user_vote.nil? ? 0 : book.user_vote

      book
    end

    @nominated_books = @nominated_books.sort do |a,b|
      if a.votes != b.votes
        a.votes <=> b.votes
      else
        Time.parse(a.date_added) <=> Time.parse(b.date_added)
      end
    end
  else
    @votes = []
    @nominated_books = []
  end

  erb :meeting
end
