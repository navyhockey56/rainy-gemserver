#####################
# About
# This file is responsible for running unicorn. Unicorn will start the
# geminabox server
# By default, the server will run on port 9292.

@dir = "#{ENV['HOME']}/rainy-gemserver/"

worker_processes 2
working_directory @dir

timeout 30

# Set the socket
listen "#{@dir}tmp/sockets/unicorn.sock", backlog: 64

# Set the process id path
pid "#{@dir}tmp/pids/unicorn.pid"

# Set log file paths
stderr_path "#{@dir}log/unicorn.stderr.log"
stdout_path "#{@dir}log/unicorn.stdout.log"
