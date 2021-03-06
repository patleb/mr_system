$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_capistrano"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_capistrano"
  s.summary     = "ExtCapistrano"
  s.description = "ExtCapistrano"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency "capistrano", "~> 3.16"
  s.add_dependency 'capistrano-rbenv', '~> 2.2'
  s.add_dependency 'capistrano-bundler', '~> 2.0'
  s.add_dependency 'capistrano-rails', '~> 1.6'
  s.add_dependency 'capistrano-rails-console'
  s.add_dependency 'capistrano-passenger'
  s.add_dependency 'capistrano-bundle_rsync'
  s.add_dependency 'mix_setting'
  s.add_dependency 'sunzistrano'
end
