#!/usr/bin/env ruby
require 'net/ssh'
# This is a simple script that will go through various hosts and check to see
# if a specified user is running MySQLd
#
# It assumes the user running the script has ssh keys setup for authentication
#
# Requires net-ssh gem and ruby compiled with openssl

raise "No user specified. Bailing." if ARGV[0].nil?
user = ARGV[0].chomp
system_user = `whoami`.chomp
hosts = [ "ovid01.u.washington.edu",
          "ovid02.u.washington.edu",
          "ovid03.u.washington.edu",
          "ovid21.u.washington.edu",
          "vergil.u.washington.edu"
          ]
hosts.each do |host|
  fork do
    Net::SSH.start(host,system_user) do |ssh|
      output = ssh.exec!("ps -U #{user} -u #{user} u")
      puts "MySQL Match on #{host}" if output =~ /mysql/
    end
  end
  Process.wait
end