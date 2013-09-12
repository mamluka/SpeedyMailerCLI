#!/usr/bin/env ruby
require 'thor'
require 'net/ssh'
require 'net/http'

class Bootstrap < Thor
  desc 'bootstrap droneIp dronePassword droneDomain ', 'Bootstraps a drone using SSH'

  def bootstrap(drone_ip, password, drone_domain)
    master_ip = Net::HTTP.get(URI.parse('http://ipecho.net/plain'))

    Net::SSH.start(drone_ip, 'root', :password => password) do |ssh|
      ssh.exec! 'apt-get update && apt-get install curl -y'
      ssh.exec! "\\curl -L 'http://#{master_ip}:8080//create-drone' | bash"
      ssh.exec! 'su drone'
      ssh.exec! 'cd ~'

      channel = ssh.open_channel do |ch|
        ch.exec "\\curl -L 'http://#{master_ip}:8080/install?droneDomain=#{drone_domain}&masterDomain=#{master_ip}' | bash" do |ch, success|
          raise 'could not execute command' unless success

          ch.on_data do |c, data|
            $stdout.print data
          end

          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do |c, type, data|
            $stderr.print data
          end

          ch.on_close { puts 'Drone is bootstrapped' }
        end
      end

      channel.wait
    end
  end
end

Bootstrap.start