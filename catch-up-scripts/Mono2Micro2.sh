#!/usr/bin/env bash
##
## Reset to beginning of Mono 2 Micro part 2
## Desired State:
##   monolith solution deployed in "coolstore-dev" project
##   inventory solution deployed in "coolstore-dev" project
##

OCP_USERNAME=${1}
POSTGRES_HOST=${2}
POSTGRES_USERNAME=${3}
POSTGRES_PASSWORD=${4}

if [ -z "$OCP_USERNAME" -o -z "$POSTGRES_HOST" -o -z "$POSTGRES_USERNAME" -o -z "$POSTGRES_PASSWORD" ] ; then
	echo "usage: $0 <ocp_username> <postgres_host> <postgres_username> <postgres_password>"
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
sed -i 's/{Azure PostgreSQL Host Name}/'${POSTGRES_HOST}'/g' src/main/resources/application.properties
sed -i 's/{ocpuser0XX}/'${OCP_USERNAME}'/g' src/main/resources/application.properties
sed -i 's/{PostgreSQL Username}/'${POSTGRES_USERNAME}'/g' src/main/resources/application.properties
sed -i 's/{PostgreSQL Password}/'${POSTGRES_PASSWORD}'/g' src/main/resources/application.properties

# Deploy to OCP
mvn clean package

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
