lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'henchman/metadata'

GEM_NAME = Henchman.name
GEM_VERSION = Henchman.version
GEM_SPEC = "#{GEM_NAME}.gemspec".freeze
GEM_FILE = "#{GEM_NAME}-#{GEM_VERSION}.gem".freeze
GEM_PATH = 'pkg'.freeze

task :help do
  system('rake -T')
end

task default: :help

desc "List all versions of #{GEM_NAME} installed"
task :list do
  system "gem list #{GEM_NAME}"
end

desc "Build #{GEM_NAME} (#{GEM_VERSION})"
task :build do
  system <<-EOF
    mkdir -p '#{GEM_PATH}' && \
    gem build '#{GEM_SPEC}' && \
    mv '#{GEM_FILE}' '#{GEM_PATH}'
  EOF
end

desc "Install #{GEM_NAME} (#{GEM_VERSION})"
task install: :build do
  system("gem install --local #{File.join(GEM_PATH, GEM_FILE)}")
end

desc "Clean #{GEM_NAME} (#{GEM_VERSION})"
task :clean do
  system "rm -vf #{File.join(GEM_PATH, GEM_FILE)}"
end

desc "Uninstall #{GEM_NAME} (#{GEM_VERSION})"
task :uninstall do
  system "gem uninstall #{GEM_NAME} -v #{GEM_VERSION}"
end

desc "Uninstalls all versions of #{GEM_NAME}"
task :purge do
  system "gem uninstall #{GEM_NAME} -a"
end
