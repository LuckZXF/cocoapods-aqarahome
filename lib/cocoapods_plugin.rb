# 必须先加载 build：若下面 `require 'cocoapods-aqarahome'` 抛错，PluginManager.safe_require
# 会中止整个插件文件，导致 Pod::Command::Build 未注册，`pod build` 不可用。
require 'cocoapods-aqarahome/command/build'
require 'cocoapods-aqarahome'
module Pod
  # hook
  @HooksManager = HooksManager
  @HooksManager.register('cocoapods-aqarahome', :post_install) do |_, _options|
    args = ['gen']
    CocoapodsAqarahome::Command.run(args)
  end
end