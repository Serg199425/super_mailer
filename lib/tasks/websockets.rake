namespace :websocket do
  desc 'Start the WebsocketRails standalone server.'
  task :start => :environment do
    require "thin"
    load "#{Rails.root}/config/initializers/websocket_rails.rb"
    load "#{Rails.root}/config/events.rb"

    options = WebsocketRails.config.thin_options

    warn_if_standalone_not_enabled!

    if options[:daemonize]
      fork do
        Thin::Controllers::Controller.new(options).start
      end
    else
        Thin::Controllers::Controller.new(options).start
    end

    puts "Websocket Rails Standalone Server listening on port #{options[:port]}"
  end

  desc 'Stop the WebsocketRails standalone server.'
  task :stop => :environment do
    require "thin"
    load "#{Rails.root}/config/initializers/websocket_rails.rb"
    load "#{Rails.root}/config/events.rb"

    options = WebsocketRails.config.thin_options

    warn_if_standalone_not_enabled!

    Thin::Controllers::Controller.new(options).stop
  end
end

def warn_if_standalone_not_enabled!
  return if WebsocketRails.standalone?
  puts "Fail!"
  puts "You must enable standalone mode in your websocket_rails.rb initializer to use the standalone server."
  exit 1
end