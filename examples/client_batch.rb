#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'eventmachine'
  gem 'em-modbus', path: __dir__ + '/..', require: 'modbus'
  gem 'logger'
end

class Client < Modbus::Client

  def poll
    transaction do |t|
      request = t.read_holding_registers 0, 100
      # request = t.read_input_status 0, 16

      request.callback do |start_addr, reg_values|
        puts "reg values @ #{start_addr}: #{reg_values.inspect}"
      end

      request.errback do |error|
        puts "error: #{error.inspect}"
      end
    end

    transaction do |t|
      request = t.read_holding_registers 100, 100
      # request = t.read_input_status 0, 16

      request.callback do |start_addr, reg_values|
        puts "reg values @ #{start_addr}: #{reg_values.inspect}"
        schedule_next_poll
      end

      request.errback do |error|
        puts "error: #{error.inspect}"
        schedule_next_poll
      end
    end
  end

end

trap 'INT' do
  EM.stop
end

EM.run do
  client = Client.new 'tcp://localhost:1502'
  client.connect
end
