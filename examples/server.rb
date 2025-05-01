#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'eventmachine'
  gem 'em-modbus', path: __dir__ + '/..', require: 'modbus'
  gem 'logger'
end

class ServerHandler
  def log
    @log ||= Logger.new(STDOUT).tap do |logger|
      logger.level = Logger::DEBUG
    end
  end
end

class ValueHandler
  def write_values(list)
    puts "ValueHandler#write_values #{list.inspect}"
  end
end

trap 'INT' do
  EM.stop
end


EM.run do
  server = Modbus::Server.new 'tcp://0.0.0.0:1502', ServerHandler.new
  value_handler = ValueHandler.new

  # coils
  server.add_register '00001.0', value_handler

  # input status (discrete iputs)
  server.add_register '10001.0', value_handler

  # input registers
  server.add_register '30101', value_handler

  # holding registers
  server.add_register '40101', value_handler
  server.start

  counter = 0
  EM.add_periodic_timer(2) do
    counter += 1

    # coils
    (0..15).each do |bit|
      value = counter.even? ? 1 : 0
      server.update_register "00001.#{bit}", counter.odd?
    end

    # input status (discrete iputs)
    (0..15).each do |bit|
      server.update_register "10001.#{bit}", counter.even?
    end

    # input registers
    server.update_register '30101', counter

    # holding registers
    server.update_register '40101', counter
  end
end
