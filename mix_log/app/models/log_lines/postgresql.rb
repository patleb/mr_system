module LogLines
  class Postgresql < LogLine
    TIMESTAMP    = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d{3})? UTC/
    ANCHOR       = /^(#{TIMESTAMP}) \[(\d+)\](?: \[\w+\]@\[\w+\])? \w+: +/
    CHECKPOINT   = /#{ANCHOR}checkpoint (starting|complete): (.+)/
    CHECKPOINTS  = /#{ANCHOR}(checkpoints are occurring too frequently) \((\d+) seconds? apart\)/
    SHUTDOWN     = /#{ANCHOR}(database system .+)(?:; last known up)? at(?: log time)? (#{TIMESTAMP})/
    READY        = /#{ANCHOR}(database system is ready) to accept/
    LOCK_WAIT    = /#{ANCHOR}(could not obtain lock) on(?: row in)? relation "([^"]+)"/
    PROCESS_WAIT = /#{ANCHOR}process (\d+) (.+)(?: for)? (\w+) on (.+) after (\d+\.\d+) ms/
    DEADLOCK     = /#{ANCHOR}Process (\d+) waits for (\w+) on (.+); blocked by process (\d+)/
    TIMEMOUT     = /#{ANCHOR}(canceling statement due to (?:lock|statement) timeout)/

    json_attribute(
      event: :string,
      duration: :integer,
      stopped_at: :datetime,
      relation: :string,
      lock: :string,
      lock_pid: :integer,
      wait_pid: :integer,
    )

    def self.parse(log, line, **)
      if (values = line.match(CHECKPOINT))
        created_at, pid, state, text = values.captures
        json_data = { event: "checkpoint_#{state == 'starting' ? 'start' : 'end'}" }
        level = :info
      elsif (values = line.match(CHECKPOINTS))
        created_at, pid, text, duration = values.captures
        json_data = { event: 'checkpoints', duration: duration.to_i }
        level = :error
      elsif (values = line.match(SHUTDOWN))
        created_at, pid, text, timestamp = values.captures
        json_data = { event: 'shutdown', stopped_at: Time.parse(timestamp) }
        level = :error
      elsif (values = line.match(READY))
        created_at, pid, text = values.captures
        json_data = { event: 'ready' }
        level = :info
      elsif (values = line.match(LOCK_WAIT))
        created_at, pid, text, relation = values.captures
        json_data = { event: 'lock_wait', relation: relation }
        level = :warn
      elsif (values = line.match(PROCESS_WAIT))
        created_at, pid, wait_pid, text, lock, relation, duration = values.captures
        json_data = { event: 'process_wait', relation: relation, lock: lock, wait_pid: wait_pid.to_i, duration: duration.to_i }
        level = :warn
      elsif (values = line.match(DEADLOCK))
        created_at, pid, wait_pid, lock, relation, lock_pid = values.captures
        json_data = { event: 'deadlock', relation: relation, lock: lock, wait_pid: wait_pid.to_i, lock_pid: lock_pid.to_i }
        level = :error
      elsif (values = line.match(TIMEMOUT))
        created_at, pid, text = values.captures
        json_data = { event: 'timeout' }
        level = :error
      elsif (values = line.match(ANCHOR))
        return { created_at: Time.parse(values.captures.first).utc, filtered: true}
      else
        return { filtered: true }
      end
      message = { text: [json_data[:event], lock, text].join!(': '), level: level }
      { created_at: Time.parse(created_at), pid: pid.to_i, message: message, json_data: json_data }
    end
  end
end
