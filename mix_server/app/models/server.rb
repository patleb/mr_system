class Server < LibRecord
  self.postgres_exception_to_error = false

  enum provider: MixServer.config.available_providers

  def self.current
    @current ||= find_or_create_by! private_ip: Process.host.private_ip, provider: Setting[:server_provider]
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
