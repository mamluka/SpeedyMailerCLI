#!/usr/bin/env ruby
require 'thor'
require 'net/ssh'
require 'net/http'

class Bootstrap < Thor
  desc 'bootstrap droneIp dronePassword droneDomain ', 'Bootstraps a drone using SSH'

  def bootstrap(drone_ip, password, drone_domain)
    master_ip = Net::HTTP.get(URI.parse('http://ipecho.net/plain'))

    p "Found master ip to be: #{master_ip}"

    Net::SSH.start(drone_ip, 'root', :password => password) do |ssh|
      p 'Install curl'
      p ssh.exec! 'apt-get update && apt-get install curl -y'
      p 'Creating drone user'
      p ssh.exec! "curl -L 'http://#{master_ip}:8080/create-drone' | bash"
      p 'Switching to drone user'
    end

    Net::SSH.start(drone_ip, 'drone', :password => password) do |ssh|

      p 'Running install script'

      channel = ssh.open_channel do |ch|
        channel.request_pty do |ch, success|
          raise "I can't get pty rquest" unless success

          ch.exec "\\curl -L 'http://#{master_ip}:8080/install?droneDomain=#{drone_domain}&masterDomain=#{master_ip}' | bash" do |ch, success|
            raise 'could not execute command' unless success

            ch.on_data do |c, data|
              if data.inspect.include?('[sudo]') || data.inspect.include?('password required for')
                channel.send_data("#{password}\n")
                sleep 1
              end
              $stdout.print data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

            ch.on_close { puts 'Drone is bootstrapped' }
          end
        end
      end
      channel.wait
    end
  end
end

Bootstrap.start
