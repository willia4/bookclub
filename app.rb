require 'sass'
require './database.rb'

# The sass rack plugin just won't work (it refuses to update the css if you change the .scss template and ignores its configuration and is generally horrible)
# so this will let us at least use sass css files without having to run compass or something. 
# The biggest downside of this is that @import won't work. I guess I could hack that in if necessary, but I'll probably just change it 
# to use compass if we ever need that. 
#
# I really hate open source sometimes. 
get '/stylesheets/:name.css' do |name|
  css_path = "./public/stylesheets/#{name}.css"
  scss_path = "./public/stylesheets/sass/#{name}.scss"

  if File.exist?(css_path)
    content_type 'text/css'
    content = File.open(css_path, 'r') { |file| file.read }

    content
  else
    halt(404) if not File.exist?(scss_path)

    content_type 'text/css'
    content = File.open(scss_path, 'r') { |file| file.read }

    engine = Sass::Engine.new content, :syntax => :scss
    engine.render  
  end  
end

configure do 
  #Database.init_amazon
end

before do
  @session_state = {
    :logged_in => false,
    :user_id => nil,
    :user_name => nil
  }
end

get '/' do
  @app_state = {:foo => "bar"}

	erb :index
end