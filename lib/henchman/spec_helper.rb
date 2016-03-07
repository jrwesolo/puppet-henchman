require 'rspec-puppet'

spec_path     = File.expand_path(File.join(Dir.pwd, 'test'))
fixture_path  = File.join(spec_path, 'fixtures')
module_path   = File.join(fixture_path, 'modules')
manifest_path = File.join(fixture_path, 'manifests')

RSpec.configure do |c|
  c.module_path       = module_path
  c.manifest_dir      = manifest_path
  c.parser            = 'future'        if ENV['FUTURE_PARSER'] == 'yes'
  c.strict_variables  = true            if ENV['STRICT_VARIABLES'] == 'yes'
  c.stringify_facts   = false           if ENV['STRINGIFY_FACTS'] == 'no'
  c.trusted_node_data = true            if ENV['TRUSTED_NODE_DATA'] == 'yes'
  c.ordering          = ENV['ORDERING'] if ENV['ORDERING']
end
