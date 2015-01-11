require 'sass'
require './exceptions/AuthorizationError.rb'
require './database/database.rb'
require './routes/login.rb'
require './routes/admin.rb'

# The sass rack plugin just won't work (it refuses to update the css if you change the .scss template and ignores its configuration and is generally horrible)
# so this will let us at least use sass css files without having to run compass or something. 
#
# I really hate open source sometimes. 
get '/stylesheets/:name.css' do |name|
  css_path = File.join($config[:css][:css_path], "#{name}.css")
  scss_path = File.join($config[:css][:scss_path], "#{name}.scss")
  
  halt(404) if not File.exist?(css_path) and not File.exist?(scss_path)

  content_type 'text/css'

  if File.exist?(css_path)
    return File.open(css_path, 'r') { |file| file.read }
  else
    content = File.open(scss_path, 'r') { |file| file.read }

    engine = Sass::Engine.new content, :syntax => :scss
    return engine.render  
  end  
end

configure do 
  # make sure that sass knows where to find includes
  Sass.load_paths << $config[:css][:scss_path]

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
end

get '*' do
  # if the user is trying to login, don't tell them they aren't logged in. They know.
  pass if request.path_info.start_with?("/signin")

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

get '/' do
  @app_state = {:foo => "bar"}

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

