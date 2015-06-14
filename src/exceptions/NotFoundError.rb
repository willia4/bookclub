require './exceptions/AppError.rb'

class NotFoundError < AppError
  def initialize(action, reason)
    super(action, reason, 404)
    self.title = "Not Found"
  end
end