# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-aqarahome/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-aqarahome'
  spec.version       = CocoapodsAqarahome::VERSION
  spec.authors       = ['zhaoxifan']
  spec.email         = ['179988305@qq.com']
  spec.description   = %q{私有库每次都拉分支最新的commit}
  spec.summary       = %q{私有库不需要每次更新都在主工程的podfile更新}
  spec.homepage      = 'https://github.com/LuckZXF/cocoapods-aqarahome'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.3.26'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'claide', '>= 1.0.2', '< 2.0'

end
