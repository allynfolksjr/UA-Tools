#!/usr/bin/env ruby
require 'net/ssh'
require 'colored'
require './netid_tools.rb'
include Netid
# This is a simple script that will go through various hosts and check to see
# if a specified user is running MySQLd
#
# It assumes the user running the script has ssh keys setup for authentication
#
# Requires net-ssh gem and ruby compiled with openssl. Pulls SSH user from
# system's `whoami` command.
#
# Required: Ruby 1.9.2+

## To-Do:
# * Consolidate SSH connect lines
# * Grab owners/administrators?


# Set up initial variables
$results = 0
raise "No user specified. Bailing." if ARGV[0].nil?
user = ARGV[0].chomp.downcase
raise "This is not a valid NetID!" unless validate_netid(user)
# get the user of whoever is running script
system_user = `whoami`.chomp
system_hostname = `hostname`.chomp
# Initialize the systems we'll check
hosts = [ "ovid01.u.washington.edu",
          "ovid02.u.washington.edu",
          "ovid03.u.washington.edu",
          "ovid21.u.washington.edu",
          "vergil.u.washington.edu"
          ]



puts "Running UA Check for NetID #{user} on behalf of #{system_user}\n".green



hosts.each do |host|
  check_for_mysql_presence(host,user,system_user)
end

puts "No MySQLds Detected".bold.blue if $results == 0
puts "Multiple MySQLds Detected!".bold.red if $results > 1
puts check_for_localhome(user,system_user) if $results > 0
quota_check(user,system_user)
