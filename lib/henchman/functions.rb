require 'puppet/version'

module Henchman
  module Functions
    def self.puppet_version
      Puppet.version
    end

    def self.future_applicable?
      tmp_ver = puppet_version
      Gem::Version.new(tmp_ver) >= Gem::Version.new('3.2') &&
        Gem::Version.new(tmp_ver) < Gem::Version.new('4')
    end

    def self.future?
      ENV['FUTURE_PARSER'] == 'true' && future_applicable?
    end
  end
end
