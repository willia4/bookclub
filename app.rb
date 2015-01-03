require 'sass'
require './database.rb'

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
    :user_id => nil,
    :user_name => nil,
    :avatar => "images/empty_avatar.png",
    :show_admin => false
  }

  # @session_state[:logged_in] = true
  # @session_state[:user_id] = 1
  # @session_state[:user_name] = "James Williams"
  # @session_state[:avatar] = "http://jameswilliams.me/avatar"
  # @session_state[:show_admin] = false
end

get '/' do
  @app_state = {:foo => "bar"}

	erb :index
end
