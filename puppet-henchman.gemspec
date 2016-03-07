lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'henchman/metadata'

Gem::Specification.new do |s|
  s.name         = Henchman.name
  s.version      = Henchman.version
  s.author       = 'Jordan Wesolowski'
  s.email        = 'jrwesolo@gmail.com'
  s.summary      = 'Unit and Integration test helper for Puppet'
  s.description  = 'Wrapper around Test Kitchen, rspec-puppet, and other tools'
  s.license      = 'MIT'
  s.homepage     = 'https://github.com/jrwesolo/puppet-henchman'
  s.files        = Dir.glob('lib/**/*')

  s.add_development_dependency 'rubocop', '~> 0.37'

  s.add_runtime_dependency 'kitchen-puppet', '~> 1.0'
  s.add_runtime_dependency 'librarian-puppet', '~> 2.2'
  s.add_runtime_dependency 'rake', '>= 0'
  s.add_runtime_dependency 'rspec-puppet', '~> 2.3'
  s.add_runtime_dependency 'test-kitchen', '~> 1.6'
end
