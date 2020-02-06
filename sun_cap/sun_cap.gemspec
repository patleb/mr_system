$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = MixBackend::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sun_cap"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/sun_cap"
  s.summary     = "SunCap"
  s.description = "SunCap"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'mix_setting'
end
