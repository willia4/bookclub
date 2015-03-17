require 'sass'
require './exceptions/AuthorizationError.rb'
require './database/database.rb'
require './routes/assets.rb'

configure do 
  #Database.init_amazon
end

before do
  @session_state = {
    :logged_in => false,
    :user_profile => nil,
    :show_admin => false,
    :session_token => nil
  }

  session_token = request.cookies[$config[:general][:login_cookie]]
  if !session_token.nil? && session_token != ""
    profile = Database::UserSessions.validate_user_session session_token
    if !profile.nil?
      @session_state[:logged_in] = true
      @session_state[:user_profile] = profile
      @session_state[:show_admin] = (profile.user_status == "admin")
      @session_state[:session_token] = session_token
    end
  end

  @page_state = {
    :site_title => $config[:general][:site_name],
    :page_title => $config[:general][:site_name]
  }

  # We miss you, Sir Terry. http://www.gnuterrypratchett.com/
  response.headers['X-Clacks-Overhead'] = "GNU Terry Pratchett"
end

[:get, :post, :put, :delete].each do |method|
  send method, '*' do
    # if the user is trying to login, don't tell them they aren't logged in. They know.
    pass if request.path_info.start_with?("/signin") || request.path_info.start_with?("/signout")

    if !@session_state[:logged_in]
      status 401
      @page_state[:page_title] = "Logged Out"
      erb :logged_out
    elsif @session_state[:user_profile].user_status == "unconfirmed"
      @page_state[:page_title] = "Unconfirmed User"
      status 401
      erb :unconfirmed_user
    else 
      pass
    end
  end
end

require './routes/login.rb'
require './routes/admin.rb'
require './routes/books.rb'
require './routes/meetings.rb'

get '/' do
  @unread_books = Database::Books.list_unread_books.sort { |a, b| -(Time.parse(a.date_added) <=> Time.parse(b.date_added)) }

  @future_meetings = (Database::Meetings.list_future_meetings.sort_by { |m| m.date }).map do |m|
    selected_book = (m.selected_book_id.nil? || m.selected_book_id == "") ? nil : Database::Books.find_book_by_book_id(m.selected_book_id)

    nominated_books = selected_book.nil? ? m.nominated_book_ids.map { |b| Database::Books.find_book_by_book_id(b) } : nil
    nominated_books = nominated_books.nil? ? nil : nominated_books.shuffle

    {:meeting => m, :selected_book => selected_book, :nominated_books => nominated_books}
  end

	erb :index
end

error do
  e = env['sinatra.error']

  error_state = {
    :generic_error => true,
    :action => "perform desired action",
    :reason => "Please try again later",
    :title => "Something went wrong"
  }

  if e.respond_to?("action") && e.respond_to?("reason") && e.respond_to?("title")
    error_state = {
      :generic_error => false,
      :action => e.action,
      :reason => e.reason,
      :title => e.title
    }
  end
  
  if e.respond_to?("status_code")
    status e.status_code
  end

  erb :error, :locals => {:error_state => error_state}
end

