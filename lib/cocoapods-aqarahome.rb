

module CocoapodsAqarahome
  require 'cocoapods-aqarahome/gem_version'
  require 'cocoapods-aqarahome/command/Podfile_Dev'
  require 'pathname'
  require 'claide'

  # 延迟加载：Podfile 解析阶段只需 DSL（dev_pods 等）；补丁逻辑在 post_install 首次执行时再加载。
  # 使用绝对路径，避免 $LOAD_PATH 上存在多个 cocoapods-aqarahome 时误解析到旧安装目录。
  post_install_patches_path = File.expand_path('cocoapods-aqarahome/post_install_patches.rb', __dir__)
  autoload :PostInstallPatches, post_install_patches_path

  autoload :Command, 'cocoapods-aqarahome/command'
  # autoload :Podfile, 'cocoapods-aqarahome/command/Podfile_Dev'
end