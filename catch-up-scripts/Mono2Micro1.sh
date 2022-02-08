#!/usr/bin/env bash

##
## Reset to beginning of Mono2Micro part 1
## Desired State: monolith solution deployed in "coolstore-dev" project
##
OCP_USERNAME=${1}

if [ -z "$OCP_USERNAME" ] ; then
	echo "Usage: $0 <username> where <username> is something like ocpuserXXX"
	exit 1
fi

# delete all projects
oc delete project $OCP_USERNAME-coolstore-dev

# sleep a bit more
echo "All projects deleted. Waiting 120 seconds to ensure they are gone"
sleep 120 

# clean the workspace
cd /projects/modernize-apps
git reset --hard
git clean -df
git clean -Xf
git pull

# checkout solution and deploy to new project
git checkout solution
git pull
cd monolith

oc new-project $OCP_USERNAME-coolstore-dev --display-name="Coolstore Monolith - Dev" || { echo "cant create project; ensure all projects gone with 'oc get projects' and try again"; exit 1; }

oc create -n $OCP_USERNAME-coolstore-dev -f https://raw.githubusercontent.com/fasalzaman/modernize-apps-labs/master/monolith/src/main/openshift/template-binary.json

oc new-app coolstore-monolith-binary-build
mvn clean package -Popenshift

# sleep a bit more
echo "Monolith created. Sleeping 10 seconds to wait for build objects to be created"
sleep 20

oc start-build coolstore --from-file=deployments/ROOT.war

# go back to master to start at the right place for scenario
mvn clean
git clean -df
git clean -Xf
git checkout master

# checkout solution for previous projects
cd ..
git checkout solution -- monolith

# start in right directory
cd /projects/modernize-apps/monolith
echo "---"
echo "Reset complete. To start in the right place: cd /projects/modernize-apps/monolith"
echo "---"
cd /projects/modernize-apps/monolith
