#!/bin/bash

PUPPET_MODULES="heat tripleo"
SCENARIO_DIR="test_scenarios"
mkdir -p ${SCENARIO_DIR}
cd ${SCENARIO_DIR}

if [ ! -d tripleo-common ]; then
  git clone https://github.com/openstack/tripleo-common
fi

if [ ! -d tripleo-heat-templates ]; then
  git clone https://github.com/hardys/tripleo-heat-templates
fi

mkdir -p puppet_modules
for d in $PUPPET_MODULES; do
  if [ ! -d puppet_modules/${d} ]; then
    git clone https://github.com/hardys/puppet-${d} puppet_modules/${d}
  fi
done

SCENARIOS=$(git ls-remote --heads https://github.com/hardys/tripleo-heat-templates | grep scenario | cut -d/ -f 3)
if [ $# -ne 1 ]; then
  echo "Please enter a valid scenario to setup: $SCENARIOS"
  exit 1
fi

if [[ $SCENARIOS =~ (^|[[:space:]])$1($|[[:space:]]) ]]; then
  echo "Configuring scenario $1"
  pushd tripleo-heat-templates
  git fetch -a 
  git checkout -b $1 origin/$1 || git checkout $1
  popd
  for d in $PUPPET_MODULES; do
    pushd puppet_modules/$d
    git fetch -a 
    git checkout -b $1 origin/$1 || git checkout $1
    popd
  done
  echo "scenario $1 configured"
  echo "Now run the following commands:"
  echo 
  echo ". stackrc"
  echo "cd $SCENARIO_DIR"
  echo "./tripleo-common/scripts/upload-puppet-modules -d puppet_modules"
  echo "openstack stack delete --yes --wait overcloud"
  echo "openstack overcloud deploy --templates ./tripleo-heat-templates"
else
  echo "Please enter a valid scenario to setup:"
  echo
  echo "$SCENARIOS"
  exit 1
fi
