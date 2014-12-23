require 'sass'

# The sass rack plugin just won't work (it refuses to update the css if you change the .scss template and ignores its configuration and is generally horrible)
# so this will let us at least use sass css files without having to run compass or something. 
# The biggest downside of this is that @import won't work. I guess I could hack that in if necessary, but I'll probably just change it 
# to use compass if we ever need that. 
#
# I really hate open source sometimes. 
get '/stylesheets/:name.css' do |name|
  path = "./public/stylesheets/sass/#{name}.scss"

  halt(404) if not File.exist?(path)

  content_type 'text/css'
  content = File.open(path, 'r') { |file| file.read }

  engine = Sass::Engine.new content, :syntax => :scss
  engine.render
end

configure do 
  
end

get '/' do
	erb :index
end