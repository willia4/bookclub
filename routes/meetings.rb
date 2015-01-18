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
      :date_added => date_added,
      :date_added_formatted => date_added.strftime("%Y-%b-%d @ %I:%M%P %Z"),
      :age_statement => "Added " + age,
      :upvoted => (b.user_vote > 0),
      :downvoted => (b.user_vote < 0)
    }
  end

  JSON.generate({:nominated_books => nominated_books})   
end

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
  raise NotFoundError.new("load the requested meeting", "The meeting could not be found") if @meeting.nil?

  if @meeting.selected_book_id.nil? || @meeting.selected_book_id == "" 
    @initial_state_json = get_json_nominated_books_for_meeting(@meeting).gsub("'", %q(\\\')) # http://stackoverflow.com/questions/10551982/replace-single-quote-with-backslash-single-quote
  else
    @initial_state_json = '';
  end

  erb :meeting
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
  raise AppError.new("voting", "this meeting is not open for voting") if (!meeting.selected_book_id.nil? && meeeting.selected_book_id != "")
  raise NotFoundError.new("voting", "the book is not nominated for this meeting") if (meeting.nominated_book_ids.find { |bid| bid == book_id}).nil?

  user_profile_id = @session_state[:user_profile].user_id
  current_votes = Database::Meetings.find_votes_for_meeting(meeting_id) 
  current_votes = current_votes.select { |v| v["book_id"] == book_id && v["user_profile_id"] == user_profile_id}
  current_vote = current_votes.size > 0 ? current_votes[0]["vote"] : 0

  vote = direction == "up" ? 1 : direction == "down" ? -1 : 0
  vote = vote + current_vote
  vote = vote < -1 ? -1 : vote > 1 ? 1 : vote

  Database::Meetings.record_vote_for_meeting(meeting_id, book_id, user_profile_id, vote)

  status 200 
  content_type :json, 'charset' => 'utf-8'
  
  get_json_nominated_books_for_meeting(meeting)
end

