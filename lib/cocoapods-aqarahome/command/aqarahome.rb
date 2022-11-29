
require 'cocoapods-aqarahome/command/Podfile_Dev'
module CocoapodsAqarahome
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Gen < Command
      # summary
      self.summary = '删除Podfile.lock和Manifest.lock 的git commit相关'

      self.description = <<-DESC
        因为考虑到私有库更新后需要到主工程手动更新podfile文件
      DESC

      # self.arguments = 'NAME'

      def initialize(argv)
        @name = 'Aqarahome'
        super
      end

      def validate!
        super
        help! 'A Pod name is required.' unless @name
      end

      def run
        # Pod::Podfile::DSL.dev_pods(['LMDashboard'],'Aqara')
      end
    end
  end
end
