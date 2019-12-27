# Rainy Gemserver
Host your own private gemserver on a Digital Ocean droplet using GemInABox, Unicorn, and NGINX.

## Setting up your Gem Server on a Droplet
### Step 1: Create a Droplet for your gems
First, create a new droplet in digital ocean. You can use the most basic size.

### Step 2: Add ruby to your droplet
After you have created your droplet, it is time to get things setup. SSH into your droplet:
```bash
ssh root@12.345.67.89
```
Note: Replace `12.345.67.89` with your droplet's ip address


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

We are going to want our gems to be added to our PATH. As such, modify your `.bashrc` to include:
```bash
PATH=$PATH:~/.gem/bin
```
You can resource your `.bashrc` with
```bash
source ~/.bashrc
```

### Step 3: Cloning the rainy-gemserver project
Once you have ruby installed, navigate to the `/root` directory and clone the rainy-gemserver repo:
```bash
cd ~/ && git clone https://github.com/navyhockey56/rainy-gemserver.git
```

This will provide you with all the file you need to get things running. Now that you have the project, you should install the dependencies:
```bash
cd ~/rainy-gemserver
bundle install
```

### Step 4: Setting up your username/password for basic auth
You will most likely want to change the username/password required for basic auth. If so, you can edit the `config.ru` file to specify as many username/password combos as you'd like. If you would like to remove the basic auth requirement, this can also be done by modifying the `config.ru` file.

### Step 5: Making rainy-gemserver a service
Now it's time to create the rainy-gemserver service for running the server. The init.d script is already written and contained within the `init.d` folder of the project. You will need to move this file over to your `/etc/init.d/` directory and configure it as well:
```bash
cp init.d/rainy-gemserver /etc/init.d/
update-rc.d rainy_gemserver defaults
```
You will now be able to stop/start/restart/status rainy-gemserver with systemctl, for example:
```bash
service rainy-gemserver start
service rainy-gemserver restart
service rainy-gemserver stop
service rainy-gemserver status
```
Make sure to start the rainy-gemserver before moving onto the next section.

## Exposing your Gemserver to the Internet
Now you've got your private Gemserver! Unfortinately, you can't access it from outside your Droplet at this point. We will use `nginx` to expose our gemserver to the internet.

### Step 1: Install NGINX
First up is installing `nginx` so that we can expose our gemserver:
```bash
apt-get update
apt-get install nginx
```

### Step 2: Configuring NGINX
NGINX keeps its configurations within `/etc/ngnix`. Start by moving into this directory:
```bash
cd /etc/nginx
```
You should find a folder called `sites-available` within your ngnix config directory. We are going to replace the `sites-available/default` file with the one provided in the rainy-gemserver repo and then reload nginx:
```bash
cp ~/rainy-gemserver/ngnix/sites-available/default /etc/ngnix/sites-available
service nginx restart
```

### Step 3: Access your GemServer
You will now be able to access your gemserver online! To do this, open `http://12.345.67.89:9292` in your favorite browser. Upon doing so, you should be prompted for your basic auth creds; when entered correctly, you should then be taken to your GemInABox homepage. Note: Replace `12.345.67.89` with your droplet's ip address.

## Adding gems to your gem server
You can now upload gems to your private gem server using the GemInABox homepage or by uploading the gem from the command line.

To upload from the command line, build the gem locally, then use your local copy of `geminabox` to push the gem to your gem server with basic auth:
```bash
gem build my-gem.gemspec
gem inabox my-gem-1.0.0.gem -g http://some_username:a_password@12.345.67.89:9292
```
Note: Replace `12.345.67.89` with your droplet's ip address  
Note: Replace `some_username` with your basic auth username, and `a_password` with your basic auth password.
