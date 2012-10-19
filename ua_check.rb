#!/usr/bin/env ruby
require 'net/ssh'
require 'colored'
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
raise "This is not a valid NetID!" if user.length >= 9
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

# Checks to see if MySQL is running on a specified host
def check_for_mysql_presence(host,user,system_user)
  Net::SSH.start(host,system_user, {auth_methods: %w( publickey )}) do |ssh|
    output = ssh.exec!("ps -U #{user} -u #{user} u")
    if output =~ /mysql/
      $results += 1
      # Grab the port number. This requires ruby 1.9.2+
      /port=(?<port>\d+)/ =~ output
      puts "MySQL Match on #{host}:#{port}".blue
    end
  end
end

# Returns location of localhome if present
def check_for_localhome(user,system_user)
  host = 'ovid02.u.washington.edu'
  Net::SSH.start(host,system_user, {auth_methods: %w( publickey )}) do |ssh|
    output = ssh.exec!("cpw -poh #{user}")
    if output =~ /Unknown/
      return "No MySQL Localhome Set for #{user}".red
    else
      return "Localhome for #{user}: #{output}"
    end
  end
end

def quota_check(user,system_user)
  host = 'ovid02.u.washington.edu'
  puts "\n"
  Net::SSH.start(host,system_user, {auth_methods: %w( publickey )}) do |ssh|
    output = ssh.exec!("quota #{user}").chomp
    # Split along newlines
    output = output.split("\n")
    # This deletes the first blank line. There be an easier way to do this
    output.delete_at(0) if output.first == ''
    # Go through each line of the output
    output.each_with_index do |line,index|
      # The first two are headers: print and ignore
      if index == 0 || index == 1
        puts line
        next
      end
      # Break the line up into elements
      line_components = line.squeeze(" ").split(" ")
      # Check to see if usage is over quota
      if line_components[1].to_f > line_components[2].to_f
        puts line.bold.red
        # If there's a grace period, it shows up in [4], so we account for that 
        # and flag if its present
      elsif line_components[4] =~ /day/i || line_components[4].to_i > line_components[5].to_i
        puts line.bold.red
      else
        puts line
      end
    end
  end
end



hosts.each do |host|
  check_for_mysql_presence(host,user,system_user)
end

puts "No MySQLds Detected".bold.blue if $results == 0
puts "Multiple MySQLds Detected!".bold.red if $results > 1
puts check_for_localhome(user,system_user) if $results > 0
quota_check(user,system_user)

