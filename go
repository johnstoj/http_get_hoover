#! /usr/bin/env bash
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
[[ -s "/usr/lib/rvm/scripts/rvm" ]] && . "/usr/lib/rvm/scripts/rvm"
rvm rvmrc trust
source .rvmrc

HAS_BUNDLER=`gem list --local |grep bundler`
if [ "$HAS_BUNDLER" = "" ]; then
	gem install bundler --no-rdoc --no-ri
fi

set -e
echo "Checking Bundler dependencies."
bundle check || bundle update

sudo -E ./http_get_hoover.rb $1
