
module CocoapodsAqarahome
  require 'colored2'
  require 'claide'
  # The primary Command for VFS.
  class Command < CLAide::Command
    require 'cocoapods-aqarahome/command/aqarahome'

    self.abstract_command = false
    self.command = 'aqarahome'
    self.version = VERSION
    self.description = 'Delete Pod.lock about git commit'
    self.plugin_prefixes = %w[claide Aqarahome]

    def initialize(argv)
      super
      return if ansi_output?

      Colored2.disable!
      String.send(:define_method, :colorize) { |string, _| string }
    end

  end
end