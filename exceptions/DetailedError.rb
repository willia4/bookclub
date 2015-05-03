require './exceptions/AppError.rb'

class DetailedError < AppError
  attr_accessor :message_dictionary
  attr_accessor :detailed_message

  def initialize(action, title, reason, detailed_message, message_dictionary = {}, status_code = 500)
    super(action, reason, status_code)

    self.title = title
    self.detailed_message = detailed_message
    self.message_dictionary = message_dictionary
  end
end
