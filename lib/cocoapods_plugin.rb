require 'cocoapods-aqarahome'
module Pod
  # hook
  @HooksManager = HooksManager
  @HooksManager.register('cocoapods-aqarahome', :post_install) do |_, _options|
    args = ['gen']
    CocoapodsAqarahome::Command.run(args)
  end
end