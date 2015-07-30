# a config.ru, for use with every rack-compatible webserver.
# SSL needs to be handled outside this, though.

# if puppet is not in your RUBYLIB:
# $LOAD_PATH.unshift('/opt/puppet/lib')

require 'fileutils'

$0 = "master"

# if you want debugging:
# ARGV << "--debug"

ARGV << "--rack"

FileUtils.mkdir(".puppet") unless File.exists?(".puppet")

# Rack applications typically don't start as root.  Set --confdir, --vardir,
# --logdir, --rundir to prevent reading configuration from
# ~/ based pathing.
ARGV << "--confdir" << File.expand_path("puppet/conf")
ARGV << "--vardir"  << File.expand_path("puppet/var")
ARGV << "--logdir"  << File.expand_path("puppet/log")
ARGV << "--rundir"  << File.expand_path("puppet/run")
ARGV << "--codedir" << File.expand_path("puppet/code")

# always_cache_features is a performance improvement and safe for a master to
# apply. This is intended to allow agents to recognize new features that may be
# delivered during catalog compilation.
ARGV << "--always_cache_features"

# NOTE: We have to intercept agent requests for the CA certificate because we
# don't want the agent to replace their local ca certificate with a copy of the
# Puppet CA because the Puppet CA has nothing to do with the Heroku load
# balancer which is using a certificate issued by digicert.com.
class HerokuSSL
  def initialize(app)
    @headers = { 'Content-Type' => 'text/plain' }
    @cacert = File.readlines('resources/heroku-bundle.crt')
    @app = app
  end

  def call(env)
    if env['REQUEST_PATH'] == '/puppet-ca/v1/certificate/ca'
      [200, @headers, @cacert]
    else
      @app.call(env)
    end
  end
end

# Use the HerokuSSL as a middleware
use HerokuSSL

# NOTE: it's unfortunate that we have to use the "CommandLine" class
#  here to launch the app, but it contains some initialization logic
#  (such as triggering the parsing of the config file) that is very
#  important.  We should do something less nasty here when we've
#  gotten our API and settings initialization logic cleaned up.
#
# Also note that the "$0 = master" line up near the top here is
#  the magic that allows the CommandLine class to know that it's
#  supposed to be running master.
#
# --cprice 2012-05-22

require 'puppet/util/command_line'
# we're usually running inside a Rack::Builder.new {} block,
# therefore we need to call run *here*.
run Puppet::Util::CommandLine.new.execute
