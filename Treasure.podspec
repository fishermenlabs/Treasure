Pod::Spec.new do |s|
  s.name             = 'Treasure'
  s.version          = '0.1.3'
  s.summary          = 'A small set of tools for deserializing JSON API objects.'

  s.description      = <<-DESC
Treasure is a small set of tools on top of Lyft's Mapper library to convert objects according to the JSON API specification.
                       DESC

  s.homepage         = 'https://github.com/fishermenlabs/Treasure'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kfweber' => 'kevinw@fishermenlabs.com' }
  s.source           = { :git => 'https://github.com/fishermenlabs/Treasure.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target     = "10.10"
  s.tvos.deployment_target    = "9.0"
  s.watchos.deployment_target = "2.0"

  s.source_files = 'Treasure/Classes/**/*'
  s.dependency 'ModelMapper', '~> 6.0.0'
end
