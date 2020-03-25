#!/usr/bin/env bash

##
## Reset to beginning of Developer Intro
## Desired State: monolith solution deployed in "coolstore-dev" project
##

# delete all projects
oc delete project ocpuser0XX-coolstore-dev

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

# undo code changes from this scenario
git checkout master -- src/main/java/com/redhat/coolstore/utils/Transformers.java
git checkout master -- src/main/webapp/app/css/coolstore.css

oc new-project ocpuser0XX-coolstore-dev --display-name="Coolstore Monolith - Dev" || { echo "cant create project; ensure all projects gone with 'oc get projects' and try again"; exit 1; }

oc create -n ocpuser0XX-coolstore-dev -f https://raw.githubusercontent.com/fasalzaman/modernize-apps-labs/master/monolith/src/main/openshift/template-binary1.json
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
echo "---"
echo "Reset complete. To start in the right place: cd $HOME/projects/monolith"
echo "---"
