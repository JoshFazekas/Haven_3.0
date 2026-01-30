#!/usr/bin/env ruby
# Script to add flavor configurations to iOS project
# Run with: ruby ios/setup_flavors.rb

require 'xcodeproj'

# Open the project
project_path = File.join(File.dirname(__FILE__), 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# Get existing configurations
debug_config = project.build_configurations.find { |c| c.name == 'Debug' }
release_config = project.build_configurations.find { |c| c.name == 'Release' }
profile_config = project.build_configurations.find { |c| c.name == 'Profile' }

# Define new configurations
new_configs = [
  { name: 'Debug-dev', base: debug_config },
  { name: 'Debug-prod', base: debug_config },
  { name: 'Release-dev', base: release_config },
  { name: 'Release-prod', base: release_config },
  { name: 'Profile-dev', base: profile_config },
  { name: 'Profile-prod', base: profile_config },
]

# Add configurations to the project
new_configs.each do |config_info|
  unless project.build_configurations.any? { |c| c.name == config_info[:name] }
    new_config = project.add_build_configuration(config_info[:name], config_info[:base].type)
    new_config.build_settings.merge!(config_info[:base].build_settings)
    puts "Added project configuration: #{config_info[:name]}"
  end
end

# Add configurations to each target
project.targets.each do |target|
  target_debug = target.build_configurations.find { |c| c.name == 'Debug' }
  target_release = target.build_configurations.find { |c| c.name == 'Release' }
  target_profile = target.build_configurations.find { |c| c.name == 'Profile' }
  
  target_configs = [
    { name: 'Debug-dev', base: target_debug },
    { name: 'Debug-prod', base: target_debug },
    { name: 'Release-dev', base: target_release },
    { name: 'Release-prod', base: target_release },
    { name: 'Profile-dev', base: target_profile },
    { name: 'Profile-prod', base: target_profile },
  ]
  
  target_configs.each do |config_info|
    unless target.build_configurations.any? { |c| c.name == config_info[:name] }
      new_config = target.add_build_configuration(config_info[:name], config_info[:base].type)
      new_config.build_settings.merge!(config_info[:base].build_settings)
      puts "Added target '#{target.name}' configuration: #{config_info[:name]}"
    end
  end
end

# Save the project
project.save
puts "\n✅ Flavor configurations added successfully!"
puts "\nNext steps:"
puts "1. Open ios/Runner.xcworkspace in Xcode"
puts "2. Set the xcconfig files for each configuration:"
puts "   - Debug-dev → Flutter/Debug-dev.xcconfig"
puts "   - Debug-prod → Flutter/Debug-prod.xcconfig"
puts "   - Release-dev → Flutter/Release-dev.xcconfig"
puts "   - Release-prod → Flutter/Release-prod.xcconfig"
puts "3. Run: cd ios && pod install"
