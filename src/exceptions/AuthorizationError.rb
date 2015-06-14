require './exceptions/AppError.rb'

class AuthorizationError < AppError
  def initialize(action, reason)
    super(action, reason, 401)
    self.title = "Unauthorized"
  end
end