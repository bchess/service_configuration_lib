#!/bin/bash
# Copyright 2015 Yelp Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e

SCRIPTS="all_nodes_that_receive
all_nodes_that_run
dump_service_configuration_yaml
services_deployed_here
services_needing_puppet_help
services_that_run_here
services_using_ssl"

SERVICES_DEPLOYED="fake_runs_on_1
fake_runs_on_2
fake_deploys_on_1
fake_deploys_on_2"

SERVICES_RUN="fake_runs_on_1
fake_runs_on_2"

SERVICES_PUPPET="fake_runs_on_1
fake_deploys_on_1"

SERVICES_NOTHING="fake_total_bunk"

# We need to get the fake services folder to look
# like it's the real services config folder
mkdir -p /nail/etc
[ -L /nail/etc/services ] || ln -s /work/tests/fake_services /nail/etc/services

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gdebi-core

if gdebi -n /work/dist/*.deb; then
  echo "Package installed correctly..."
else
  echo "Dpkg install failed!"
  exit 1
fi

if python -c 'import service_configuration_lib' >/dev/null; then
  echo "Library can be imported..."
else
  echo "Package installed but library failed to import!"
  exit 1
fi

for scr in $SCRIPTS
do
  which $scr >/dev/null || (echo "$scr failed to install!"; exit 1)
done
echo "All scripts are in the path..."

for srv in $SERVICES_DEPLOYED
do
  if ! services_deployed_here | grep -q $srv; then
  	echo "Service $srv ISN'T showing up in services_deployed_here but should be"
  	exit 1
  fi
done

for srv in $SERVICES_RUN
do
  if ! services_that_run_here | grep -q $srv; then
  	echo "Service $srv ISN'T showing up in services_that_run_here but should be"
  	exit 1
  fi
done

for srv in $SERVICES_PUPPET
do
  if ! services_needing_puppet_help | grep -q $srv; then
  	echo "Service $srv ISN'T showing up in services_needing_puppet_help but should be"
  	exit 1
  fi
done

for srv in $SERVICES_NOTHING
do
  if services_deployed_here | grep -q $srv; then
  	echo "Service $srv IS showing up in services_deployed_here but shouldn't be"
  	exit 1
  fi
  if services_that_run_here | grep -q $srv; then
  	echo "Service $srv IS showing up in services_that_run_here but shouldn't be"
  	exit 1
  fi
  if services_needing_puppet_help | grep -q $srv; then
  	echo "Service $srv IS showing up in services_needing_puppet_help but shouldn't be"
  	exit 1
  fi
done

echo "Everything worked! Exiting..."
