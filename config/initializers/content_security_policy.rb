# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https

#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
#   urls = Setting.slice(:pgrest_url, :geoserver_url).each_with_object([]) do |(_name, url), urls|
#     urls << url.gsub(%r{([^:/])/.*$}, '\1') unless url.include? "://#{Setting[:server]}/"
#   end
  urls = []
  if Rails.env.development?
    policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035", *urls
    if defined? WebConsole
      policy.script_src  :self, :https, :unsafe_eval, :unsafe_inline
    else
      policy.script_src  :self, :https, :unsafe_eval
    end
  else
    policy.connect_src :self, *urls
    if defined? WebConsole
      policy.script_src  :self, :https, :unsafe_inline
    else
      policy.script_src  :self, :https
    end
  end
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true