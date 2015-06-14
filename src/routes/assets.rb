require 'sass'
require './database/redis.rb'

configure do 
  # make sure that sass knows where to find includes
  Sass.load_paths << $config[:css][:scss_path]
end

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
    f = File.open(scss_path, 'r')
    content = Database::Redis.find_css(name, f.mtime.getutc)

    if content.nil?
      content = f.read
      engine = Sass::Engine.new content, :syntax => :scss
      content = engine.render  
      Database::Redis.cache_css(name, f.mtime.getutc, content)
    end
    f.close

    return content
  end  
end

#sigh
get '/javascripts/:name' do |name|
  real_path = File.join("/www/bookclub/public/real_javascripts/", "#{name}")
  halt(404) if not File.exist?(real_path)

  content_type "text/javascript"
  
  File.open(real_path, 'r') { |file| file.read }
end