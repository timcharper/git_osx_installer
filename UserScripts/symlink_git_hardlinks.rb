#!/usr/bin/env ruby

git_binary = '/usr/local/git/bin/git'

[
  ['git'          , '/usr/local/git/bin'], 
  ['../../bin/git', '/usr/local/git/libexec/git-core']
].each do |link, path|
  Dir.glob(File.join(path, '*')).each do |file|
    next if file == git_binary
		puts "#{file} #{File.size(file)} == #{File.size(git_binary)}"
    next unless File.size(file) == File.size(git_binary)
    puts "Symlinking #{file}"
    puts `ln -sf #{link} #{file}`
  end
end

