#!/usr/bin/env ruby
require 'net/ssh'
# This is a simple script that will go through various hosts and check to see
# if a specified user is running MySQLd
#
# It assumes the user running the script has ssh keys setup for authentication
#
# Requires net-ssh gem and ruby compiled with openssl. Pulls SSH user from
# system's `whoami` command.


# Set up initial variables
$results = 0
raise "No user specified. Bailing." if ARGV[0].nil?
user = ARGV[0].chomp
# get the user of whoever is running script
system_user = `whoami`.chomp
# Initialize the systems we'll check
hosts = [ "ovid01.u.washington.edu",
          "ovid02.u.washington.edu",
          "ovid03.u.washington.edu",
          "ovid21.u.washington.edu",
          "vergil.u.washington.edu"
          ]


# Checks to see if MySQL is running on a specified host
def check_for_mysql_presence(host,user,system_user)
  Net::SSH.start(host,system_user) do |ssh|
    output = ssh.exec!("ps -U #{user} -u #{user} u")
    if output =~ /mysql/
      $results += 1
      puts "MySQL Match on #{host}"
    end
  end
end

# Returns location of localhome if present
def check_for_localhome(user,system_user)
  host = "ovid02.u.washington.edu"
  Net::SSH.start(host,system_user) do |ssh|
    output = ssh.exec!("cpw -poh #{user}")
    if output =~ /Unknown/
      return "No MySQL Localhome Set for #{user}"
    else
      return "Localhome for #{user}: #{output}"
    end
  end
end


hosts.each do |host|
  check_for_mysql_presence(host,user,system_user)
end

puts "No MySQLds Detected" if $results == 0
puts "Multiple MySQLds Detected!" if $results > 1
puts check_for_localhome(user,system_user)
