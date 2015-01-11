class AppError < StandardError
  attr_accessor :action
  attr_accessor :reason
  attr_accessor :status_code 
  attr_accessor :title

  def initialize(action, reason, status_code = 500)
    super("Unable to '#{action}': '#{reason}'.")

    self.action = action
    self.reason = reason
    self.status_code = status_code
    self.title = "Something went wrong generic"
  end

end