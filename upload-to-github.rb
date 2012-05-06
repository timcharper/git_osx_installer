#! /usr/bin/env ruby
#
# ruby upload-to-github.rb user user/repo file '(description)'
#

require 'rubygems'
require 'json'

if ARGV.size < 3
  puts "\nUSAGE: upload-to-github.rb [user] [user/repo] [filepath] ('description')"
  exit
end

user = ARGV[0]
repo = ARGV[1]
file = ARGV[2]
desc = ARGV[3] rescue ''

def url(path)
  "https://api.github.com#{path}"
end

size = File.size(file)
fname = File.basename(file)

pass=`git gui--askpass "Password for #{user}"`.chomp

# create entry
args = 
data = `curl -s -XPOST -d '{"name":"#{fname}","size":#{size},"description":"#{desc}"}' -u "#{user}:#{pass}" #{url("/repos/#{repo}/downloads")}`
data = JSON.parse(data)

# upload file to bucket
cmd  = "curl -s "
cmd += "-F \"key=#{data['path']}\" "
cmd += "-F \"acl=#{data['acl']}\" "
cmd += "-F \"success_action_status=201\" "
cmd += "-F \"Filename=#{data['name']}\" "
cmd += "-F \"AWSAccessKeyId=#{data['accesskeyid']}\" "
cmd += "-F \"Policy=#{data['policy']}\" "
cmd += "-F \"Signature=#{data['signature']}\" "
cmd += "-F \"Content-Type=#{data['mime_type']}\" "
cmd += "-F \"file=@#{file}\" "
cmd += "https://github.s3.amazonaws.com/"

xml = `#{cmd}`

if m = /\<Location\>(.*)\<\/Location\>/.match(xml)
  puts "Your file is uploaded to:"
  puts m[1].gsub('%2F', '/')  # not sure i want to fully URL decode this, but these will not do
else
  puts "Upload failed. Response is:\n\n #{xml}"
end
