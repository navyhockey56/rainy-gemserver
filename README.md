# How to setup a Private GemServer on Digital Ocean with nginx and geminabox

## Setting up your GemServer on a Droplet
### Step 1: Create a Droplet for your gems
First, create a new droplet in digital ocean. You can use the most basic size.

### Step 2: Add ruby to your droplet
After you have created your droplet, it is time to get things setup. SSH into your droplet:
```bash
ssh root@12.345.67.89
```

Now that you're in your droplet, you will find that you do not have ruby installed. You will need to install the version of ruby you plan to run the gemserver with. You can use `snap` to perform your install. To determine which versions of ruby are available via `snap`, run the command:
```bash
snap info ruby
```

The version at the tob of the list under `stable: ...` will be what gets installed if you were to run:
```bash
snap install ruby --classic
```
If the stable version is not the one you wish to use, you can specify a previous version by referencing it's channel. For instance, say we wanted to use `ruby 2.5.7`, then we could install it with:
```bash
snap install ruby --channel 2.5/stable --classic
```

### Step 3: Add geminabox to your droplet
We will use `GemInABox` to host our gemserver. You can install it with:
```bash
gem install geminbox
```

Now that you have `geminabox` installed, you will want to create a directory for it on your droplet. For this example, we will create a directory called `geminabox` within the root directory:
```bash
mkdir /root/geminabox
cd /root/geminabox
```

### Step 4: Setting up geminabox
Now that you have `geminabox` installed, you will need to add it's configuration file. This is where we'll setup basic auth (Note: You can setup no authorization or other types of authorization as well using `GemInABox`). Create the config file with:
```bash
touch config.ru
```

Now add the following to your `config.ru` file:
```ruby
require "rubygems"
require "geminabox"

# The location to store the gems locally. Currently setup to store them in your
# /root/geminabox/data folder, but you can change this location to anywhere.
Geminabox.data = "./data"

# Remove this block if you don't want to add basic auth
use Rack::Auth::Basic, 'GemInAbox' do |username, password|
  # Add as many username/passwords as you want here.
  username == 'some_username' && password == 'a_password'
end

# Starts the gemserver
run Geminabox::Server

```

### Step 5: Adding rackup
In order to run our `geminabox` server, we will need `rackup`. To add `rackup` to your machine, run:
```bash
gem install rackup
```

This will add rackup to `/root/.gem/bin`.

### Step 6: Starting the gemserver

Now that you have your configuration for `geminabox` setup, you will want to start up the gemserver to make sure things are working. To start the gemserver, simply run `rackup` from the `/root/geminabox` directory:
```bash
/root/.gem/bin/rackup
```

Once you've confirmed that you're server successfully started, you can spin it down with `ctr+c`.

## Exposing your Gemserver to the Internet
Now you've got your private Gemserver! Unfortinately, you can't access it from outside your Droplet at this point. We will use `nginx` to expose our gemserver to the internet.

### Step 1: Install NGINX
First up is installing `nginx` so that we can expose our gemserver:
```bash
apt-get update
apt-get install nginx
```

### Step 2: Installing unicorn
You will need to install unicorn:
```bash
gem install unicorn
```

#### Setting up unicorn as a service
We want to create a service for running unicorn. To do this, we will create an init.d script in `/etc/init.d/` called `unicorn_geminabox`. First, create the script's file:
```bash
touch /etc/init.d/unicorn_geminabox
chmod 755 /etc/init.d/unicorn_geminabox
```

Next, fill in the contents of the script with:
```bash
#!/bin/sh

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the unicorn app server
# Description:       starts unicorn using start-stop-daemon
### END INIT INFO

set -e

USAGE="Usage: $0 <start|stop|restart|upgrade|rotate|force-stop>"

# app settings
USER="root"
APP_NAME="geminabox"
APP_ROOT="/$USER/$APP_NAME"
ENV="production"

# environment settings
#PATH="/home/$USER/.rbenv/shims:/home/$USER/.rbenv/bin:$PATH"
CMD="cd $APP_ROOT && bundle exec unicorn -p 9292 -c config/unicorn.rb -E $ENV -D"
PID="$APP_ROOT/tmp/pids/unicorn.pid"
OLD_PID="$PID.oldbin"

# make sure the app exists
cd $APP_ROOT || exit 1

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
  test -s $OLD_PID && kill -$1 `cat $OLD_PID`
}

case $1 in
  start)
    sig 0 && echo >&2 "Already running" && exit 0
    echo "Starting $APP_NAME"
    su - $USER -c "$CMD"
    ;;
  stop)
    echo "Stopping $APP_NAME"
    sig QUIT && exit 0
    echo >&2 "Not running"
    ;;
  force-stop)
    echo "Force stopping $APP_NAME"
    sig TERM && exit 0
    echo >&2 "Not running"
    ;;
  restart|reload|upgrade)
    sig USR2 && echo "reloaded $APP_NAME" && exit 0
    echo >&2 "Couldn't reload, starting '$CMD' instead"
    $CMD
    ;;
  rotate)
    sig USR1 && echo rotated logs OK && exit 0
    echo >&2 "Couldn't rotate logs" && exit 1
    ;;
  *)
    echo >&2 $USAGE
    exit 1
    ;;
esac

```

### Step 3: Configuring NGINX
NGINX keeps its configurations within `/etc/ngnix`. Start by moving into this directory:
```bash
cd /etc/nginx
```
You should find a folder called `sites-available` within your ngnix config directory. Add the file `my_private_gemserver.com` to the `sites-available` folder containing the following info:
```
upstream unicorn {
  server unix:/root/geminabox/tmp/sockets/unicorn.sock;
}

server {
  listen  80;
  server_name localhost;

  root /root/geminabox/public;

  error_page  404          /404.html;
  error_page  500          /500.html;

  try_files $uri/index.html $uri @unicorn;

  access_log /root/geminabox/log/access_log;

  client_max_body_size 10000k;

  location @unicorn {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded_Proto $scheme;
    proxy_redirect off;
    proxy_pass http://unicorn;
  }
}

```

