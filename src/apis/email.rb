require 'mail'

module APIs
  module Email
    def self.send_mail(to_address, subject, plain_text, html = nil)
      # Mandrill is going away. 
      # Stop sending emails for now. 
      #
      # mail_job = fork do
      #   Mail.defaults do
      #     delivery_method :smtp, {
      #       :port => $config[:smtp][:port],
      #       :address => $config[:smtp][:server],
      #       :user_name => $config[:smtp][:username],
      #       :password => $config[:smtp][:password]
      #     }  
      #   end

      #   mail = Mail.deliver do 
      #     to to_address
      #     from $config[:smtp][:from_address]
      #     subject subject

      #     text_part do
      #       body plain_text
      #     end

      #     if !html.nil?
      #       content_type 'text/html; charset=UTF-8'
      #       body html
      #     end
      #   end
      # end
    end
  end
end