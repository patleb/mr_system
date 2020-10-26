class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze

  delegate :backtrace, to: :@exception
  attr_reader :name, :data

  def self.rescue_class
    name.delete_suffix('Error').to_const || Rescue
  end

  def initialize(exception, data = nil)
    @exception = exception
    @name = exception.class.name
    @data = data || {}
  end

  def message
    <<~EOF.strip
      #{RESCUE}[#{name}]
      #{data.pretty_json}
      #{before_backtrace}
    EOF
  end

  def before_backtrace
    @exception.message
  end
end