class AppError < StandardError
  attr_reader :action
  attr_reader :reason

  def initialize(action, reason)
    super("Unable to '#{action}': '#{reason}'.")

    @action = action
    @reason = reason
  end

end