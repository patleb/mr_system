class LogLine < LibRecord
  class IncompatibleLogLine < ::StandardError; end

  belongs_to :log

  enum type: MixLog.config.available_types

  def self.push(log_id, *)
    raise NotImplementedError
  end

  def self.push_all(log_id, lines)
    lines.each{ |line| line[:log_id] = log_id }
    insert_all(lines)
  end

  def self.parse(line)
    raise NotImplementedError
  end

  def self.finalize
  end

  def self.insert_all(attributes, **)
    attributes.each{ |row| row[:type] = name }
    super
  end
end