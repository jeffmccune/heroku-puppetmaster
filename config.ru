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

