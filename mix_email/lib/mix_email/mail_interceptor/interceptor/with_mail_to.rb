require 'mail_interceptor'

module MailInterceptor::Interceptor::WithMailTo
  def initialize(options = {})
    options[:forward_emails_to] ||=
      if defined?(Preference) && Preference.has_key?(:mail_to)
        Preference[:mail_to]
      else
        Setting[:mail_to]
      end
    super
  end
end

MailInterceptor::Interceptor.prepend MailInterceptor::Interceptor::WithMailTo
interceptor = MailInterceptor::Interceptor.new
ActionMailer::Base.register_interceptor(interceptor)
ActionMailer::Base.register_preview_interceptor(interceptor)
