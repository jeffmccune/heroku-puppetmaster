# Puppet Master on Heroku

A proof of concept for running the Puppet master on Heroku.  The goal is to
quickly get a puppet master up and running for personal use and testing.

# Warning on Security

In order to get this to work the Puppet security model has been modified to
authorize all requests.  As a result, this proof of concept is only useful for
managing configurations that do not have any sensitive information.  Do not put
passwords or private keys or other sensitive data because anyone on the public
internet will be able to read the information from the heroku app.

The modifications can be seen in the [auth.conf](puppet/conf/auth.conf) file.
The change is to allow all requests, even those coming from unauthenticated
clients.

# Directories

Deploy puppet manifests and modules into [the code directory](puppet/code) as
per the normal [directory
environment](https://docs.puppetlabs.com/puppet/4.2/reference/environments_configuring.html)
mechanism.

# Quick Start

To quickly get started with a personal Puppet Master running in heroku, follow
these steps.

First, clone this repository to your local workstation and change directories
to the root directory of the repository.

Create a new heroku app for the project:

    heroku apps:create

Deploy the HEAD of the master branch to heroku:

    $ git push heroku master
    Counting objects: 279, done.
    Delta compression using up to 8 threads.
    Compressing objects: 100% (180/180), done.
    Writing objects: 100% (279/279), 55.19 KiB | 0 bytes/s, done.
    Total 279 (delta 82), reused 224 (delta 66)
    remote: Compressing source files... done.
    remote: Building source:
    remote:
    remote: -----> Ruby app detected
    remote: -----> Compiling Ruby/Rack
    remote: -----> Using Ruby version: ruby-2.1.4
    remote: -----> Installing dependencies using 1.9.7
    remote:        Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin -j4 --deployment
    remote:        Fetching gem metadata from https://rubygems.org/..........
    remote:        Fetching version metadata from https://rubygems.org/..
    remote:        Installing CFPropertyList 2.2.8
    remote:        Installing json_pure 1.8.2
    remote:        Installing facter 2.4.4
    remote:        Using bundler 1.9.7
    remote:        Installing rack 1.6.4
    remote:        Installing hiera 3.0.1
    remote:        Installing puma 2.12.2
    remote:        Installing puppet 4.2.1
    remote:        Bundle complete! 3 Gemfile dependencies, 8 gems now installed.
    remote:        Gems in the groups development and test were not installed.
    remote:        Bundled gems are installed into ./vendor/bundle.
    remote:        Bundle completed (7.05s)
    remote:        Cleaning up the bundler cache.
    remote: -----> Writing config/database.yml to read from DATABASE_URL
    remote:
    remote: -----> Discovering process types
    remote:        Procfile declares types -> web
    remote:        Default types for Ruby  -> console, rake
    remote:
    remote: -----> Compressing... done, 19.7MB
    remote: -----> Launching... done, v4
    remote:        https://radiant-harbor-1863.herokuapp.com/ deployed to Heroku
    remote:
    remote: Verifying deploy... done.
    To https://git.heroku.com/radiant-harbor-1863.git
     * [new branch]      master -> master

With the app deployed, install puppet locally using bundler:

    $ bundle install --path .bundle/gems/
    Fetching gem metadata from https://rubygems.org/..........
    Installing CFPropertyList 2.2.8
    Installing facter 2.4.4
    Installing json_pure 1.8.2
    Installing hiera 3.0.1
    Installing puma 2.12.2
    Installing puppet 4.2.1
    Installing rack 1.6.4
    Using bundler 1.7.5
    Your bundle is complete!
    It was installed into ./.bundle/gems
    bundle install --path .bundle/gems/  3.49s user 1.32s system 37% cpu 12.943 total

Store the hostname of the heroku app in a variable:

    $ SERVER=radiant-harbor-1863.herokuapp.com

And finally run the agent against the server.  Port 443 is necessary.

    $ bundle exec puppet agent --test --server $SERVER\
       --masterport=443 \
       --no-certificate_revocation --certname=agent1
    Info: Creating a new SSL key for agent1
    Info: Caching certificate for ca
    Info: csr_attributes file loading from /Users/jeff/.puppetlabs/etc/puppet/csr_attributes.yaml
    Info: Creating a new SSL certificate request for agent1
    Info: Certificate Request fingerprint (SHA256): 6A:F8:17:E0:D7:8E:03:23:B8:10:EF:85:62:DC:86:2E:A4:9A:B4:F0:3D:6B:00:CD:06:7C:9A:69:24:D2:FF:F2
    Info: Caching certificate for agent1
    Info: Caching certificate for ca
    Info: Retrieving pluginfacts
    Notice: /File[/Users/jeff/.puppetlabs/opt/puppet/cache/facts.d]/mode: mode changed '0755' to '0700'
    Info: Retrieving plugin
    Info: Caching catalog for agent1
    Info: Applying configuration version '1438300923'
    Notice: Hello World!
    Notice: /Stage[main]/Helloworld/Notify[Hello World!]/message: defined 'message' as 'Hello World!'
    Info: Creating state file /Users/jeff/.puppetlabs/opt/puppet/cache/state/state.yaml
    Notice: Applied catalog in 0.01 seconds
    bundle exec puppet agent --test --server radiant-harbor-1863.herokuapp.com     6.73s user 0.55s system 60% cpu 12.024 total

# Differences from on-premise puppet master

The main difference between a heroku deployment of puppet master and a typical
deployment is the handling of the CA certificate.  The puppet agent downloads a
copy of the CA certificate it uses to validate the server authenticity.  This
is a REST API call to the `/puppet-ca/v1/certificate/ca` resource.  Puppet
master will return a copy of the Puppet CA self-signed certificate, which will
cause the agent to error out trying to connect to the Heroku front end load
balancer.  This is because heroku apps use a wildcard SSL certificate issued by
DigiCert.  To overcome this problem, this repository intercepts these URL's
using a Rack middleware and returns a copy of the DigiCert Root CA.  This, in
turn, allows the puppet agent to verify the server as authentic.

See the `HerokuSSL` class in [config.ru](config.ru) for the implementation of
this middleware.
