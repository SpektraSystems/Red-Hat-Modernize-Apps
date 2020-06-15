#!/usr/bin/env bash
##
## Reset to beginning of Reactive Microservices
## Desired State:
##   monolith solution deployed in "coolstore-dev" project
##   inventory solution deployed in "inventory" project
##

OCP_USERNAME=${1}
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

# checkout solution and deploy monolith to dev project
cd monolith
git checkout solution
git pull
oc new-project $OCP_USERNAME-coolstore-dev --display-name="Coolstore Monolith - Dev" || { echo "cant create project - ensure all projects gone with oc get projects and try again" ; exit 1; }

oc create -n $OCP_USERNAME-coolstore-dev -f https://raw.githubusercontent.com/fasalzaman/modernize-apps-labs/master/monolith/src/main/openshift/template-binary.json

oc new-app coolstore-monolith-binary-build
mvn clean package -Popenshift

# sleep a bit more
echo "Monolith created. Sleeping 10 seconds to wait for build objects to be created"
sleep 20

oc start-build coolstore --from-file=deployments/ROOT.war

# deploy inventory solution to inventory project
cd /projects/modernize-apps/inventory
mvn clean package
mvn fabric8:deploy -Popenshift


# go back to master to start at the right place for scenario
mvn clean
git clean -df
git clean -Xf
git checkout master

# checkout solution for previous projects
cd ..
git checkout solution -- monolith
git checkout solution -- inventory

# start in right directory
cd /projects/modernize-apps/catalog
echo "---"
echo "Reset complete. To start in the right place: cd /projects/modernize-apps/catalog"
echo "---"
