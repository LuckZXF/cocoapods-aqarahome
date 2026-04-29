

module CocoapodsAqarahome
  require 'cocoapods-aqarahome/gem_version'
  require 'cocoapods-aqarahome/post_install_patches'
  require 'cocoapods-aqarahome/command/Podfile_Dev'
  require 'pathname'
  require 'claide'
  autoload :Command, 'cocoapods-aqarahome/command'
  # autoload :Podfile, 'cocoapods-aqarahome/command/Podfile_Dev'
end