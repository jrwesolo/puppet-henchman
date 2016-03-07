require 'henchman/functions'
require 'rspec/core/rake_task'
require 'kitchen'

task default: :help

def print_section(str)
  puts "==> \e[0;34m#{str}\e[0m"
end

desc 'Display the list of available rake tasks'
task :help do
  system('rake -T')
end

exclude_paths = [
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*',
  'test/**/*'
]

# puppet-lint
begin
  require 'puppet-lint/tasks/puppet-lint'
  Rake::Task[:lint].clear
  # Relative is not able to be set within the context of PuppetLint::RakeTask
  PuppetLint.configuration.relative = true
  PuppetLint::RakeTask.new(:lint) do |config|
    config.fail_on_warnings = true
    config.ignore_paths = exclude_paths
    config.disable_checks = %w(
      80chars
      class_parameter_defaults
      class_inherits_from_params_class
      documentation
      single_quote_string_with_variables
    )
  end
rescue LoadError
  desc 'Not available, install puppet-lint gem'
  task :lint do
    warn('Skipping lint validation, puppet-lint gem missing')
  end
end

Rake::Task[:lint].enhance ['lint:section']

namespace :lint do
  task :section do
    print_section('Lint Validation')
  end
end

# puppet-syntax
begin
  require 'puppet-syntax/tasks/puppet-syntax'
  PuppetSyntax.future_parser = Henchman::Functions.future?
  PuppetSyntax.exclude_paths ||= []
  exclude_paths.each do |p|
    unless PuppetSyntax.exclude_paths.include?(p)
      PuppetSyntax.exclude_paths << p
    end
  end
  PuppetSyntax.hieradata_paths = ['spec/fixtures/hieradata/test.yaml']
  Rake::Task['syntax:manifests'].enhance ['syntax:section']
  Rake::Task['syntax:templates'].enhance ['syntax:section']
  Rake::Task['syntax:hiera:yaml'].enhance ['syntax:section']
rescue LoadError
  desc 'Not available, install puppet-syntax gem'
  task :syntax do
    warn('Skipping syntax validation, puppet-syntax gem missing')
  end
  Rake::Task[:syntax].enhance ['syntax:section']
end

namespace :syntax do
  task :section do
    title = 'Syntax Validation'
    title << ' (with future parser)' if Henchman::Functions.future?
    print_section(title)
  end
end

# metadata-json-lint
begin
  require 'metadata_json_lint'
  desc 'Validate metadata.json file'
  task :metadata do
    MetadataJsonLint.parse('metadata.json') if File.exist?('metadata.json')
  end
rescue LoadError
  desc 'Not available, install metadata-json-lint gem'
  task :metadata do
    warn('Skipping metadata validation, metadata-json-lint gem missing')
  end
end

Rake::Task[:metadata].enhance ['metadata:section']

namespace :metadata do
  task :section do
    print_section('Metadata Validation')
  end
end

def source_dir
  Dir.pwd
end

def spec_dir
  File.join(source_dir, 'spec')
end

def unit_dir
  File.join(source_dir, 'test/unit')
end

def modules_dir
  File.join(source_dir, 'test/fixtures/modules')
end

def manifests_dir
  File.join(source_dir, 'test/fixtures/manifests')
end

def module_name
  metadata_file = File.join(source_dir, 'metadata.json')
  if File.exist?(metadata_file)
    require 'json'
    JSON.parse(File.read(metadata_file))['name'].split('-', 2).last
  else
    raise "Unable to find #{metadata_file}, cannot continue"
  end
end

namespace :spec do
  task :clean do
    # clean out all modules
    FileUtils.mkdir_p(modules_dir)
    module_entries = Dir.entries(modules_dir)
    module_entries.reject { |x| ['.', '..'].include?(x) }.each do |entry|
      FileUtils.rm_rf(File.join(modules_dir, entry), secure: true)
    end
  end

  task :prep do
    FileUtils.mkdir_p(modules_dir)
    # Install dependencies for module
    system("librarian-puppet install --path #{modules_dir} --destructive")
  end

  namespace :unit do
    task :prep do
      # Setup spec symlink to test/unit for rspec happiness
      FileUtils.rm_f(spec_dir) if File.symlink?(spec_dir)
      if !File.exist?(spec_dir)
        FileUtils.ln_sf(unit_dir, spec_dir)
      else
        raise("#{spec_dir} exists is not symlink, cannot continue")
      end
      # Setup self via symlink (librarian does not do this for us)
      FileUtils.mkdir_p(modules_dir)
      full_module_path = File.join(modules_dir, module_name)
      FileUtils.rm_f(full_module_path) if File.symlink?(full_module_path)
      if !File.exist?(full_module_path)
        FileUtils.ln_sf(source_dir, full_module_path)
      else
        raise("#{full_module_path} exists and is not symlink, cannot continue")
      end
      # Setup manifests
      FileUtils.mkdir_p(manifests_dir)
      FileUtils.touch(File.join(manifests_dir, 'site.pp'))
    end

    task :clean do
      # clean up spec_dir link to unit_dir
      if File.symlink?(spec_dir)
        FileUtils.rm_f(spec_dir)
      elsif File.exist?(spec_dir)
        raise("#{spec_dir} exists and is not symlink, cannot continue")
      end
      # Clear out self symlink, Kitchen does this for us
      full_module_path = File.join(modules_dir, module_name)
      if File.symlink?(full_module_path)
        FileUtils.rm_f(full_module_path)
      elsif File.exist?(full_module_path)
        raise("#{full_module_path} exists and is not symlink, cannot continue")
      end
      # clean up manifests, if applicable
      if File.zero?(File.join(manifests_dir, 'site.pp'))
        FileUtils.rm_f(File.join(manifests_dir, 'site.pp'))
      end
    end

    task :section do
      title = 'Unit Tests'
      title << " (Puppet #{Henchman::Functions.puppet_version}"
      title << ' with future parser' if Henchman::Functions.future?
      title << ')'
      print_section(title)
    end
  end # namespace :unit

  desc '' # Hide this task by default
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/{classes,defines,functions,hosts,types,unit}/**/*_spec.rb'
  end

  namespace :integration do
    task :section do
      print_section('Integration Tests')
    end

    task manual: ['spec:prep', 'spec:unit:clean']
  end

  task :integration, [:destroy] do |_t, args|
    if args[:destroy]
      case args[:destroy].downcase
      when 'never', 'no'
        destroy_opt = :never
      when 'always', 'yes',
        destroy_opt = :always
      else
        destroy_opt = :passing
      end
    else
      destroy_opt = :passing
    end
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |i|
      i.test(destroy_opt)
    end
  end
end

# Prerequisites for spec:unit task
Rake::Task['spec:unit'].enhance [
  'spec:unit:section',
  'spec:prep',
  'spec:unit:prep'
]

# Run after spec:unit task
Rake::Task['spec:unit'].enhance do
  Rake::Task['spec:unit:clean'].invoke
end

# Prerequisites for spec:integration task
Rake::Task['spec:integration'].enhance [
  'spec:integration:section',
  'spec:prep',
  'spec:unit:clean'
]

# Prerequisites for spec:clean
Rake::Task['spec:clean'].enhance ['spec:unit:clean']

# Alias for spec:unit
desc 'Run unit tests'
task unit: 'spec:unit'

# Alias for spec:integration
desc 'Run integration tests'
task :integration, [:destroy] => 'spec:integration'

namespace :integration do
  # Alias for spec:integration:manual
  desc 'Prepare for integration tests run manually'
  task manual: 'spec:integration:manual'
end

# Alias for spec:clean
desc 'Clean up after spec tests'
task clean: 'spec:clean'

# Alias for metadata, lint, syntax
desc 'Run metadata, lint, and syntax tasks'
task style: [:metadata, :lint, :syntax]
