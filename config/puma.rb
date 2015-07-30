workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 64)
threads 4, threads_count

rackup      DefaultRackup
port        ENV['PORT']     || 18140
environment ENV['RACK_ENV'] || 'production'

# The directory to operate out of
directory  File.expand_path '.'
# The PID of the puma server
pidfile    File.expand_path 'puppet/run/puma.pid'
state_path File.expand_path 'puppet/run/puma.state'

# on_worker_boot do
#   puts "on_worker_boot called!"
# end

preload_app!
