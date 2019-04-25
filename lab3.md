# SCENARIO 2: A Developer Introduction to OpenShift

* Purpose: Learn how developing apps is easy and fun
* Difficulty: `intermediate`
* Time: `45-60 minutes`

## Intro
In the previous scenario you learned how to take an existing application to the cloud with JBoss EAP and OpenShift, and you got a glimpse into the power of OpenShift for existing applications.

In this scenario you will go deeper into how to use the OpenShift Container Platform as a developer to build and deploy applications. We'll focus on the core features of OpenShift as it relates to developers, and you'll learn typical workflows for a developer (develop, build, test, deploy, and repeat).

## Let's get started

If you are not familiar with the OpenShift Container Platform, it's worth taking a few minutes to understand the basics of the platform as well as the environment that you will be using for this workshop.

The goal of OpenShift is to provide a great experience for both Developers and System Administrators to develop, deploy, and run containerized applications.  Developers should love using OpenShift because it enables them to take advantage of both containerized applications and orchestration without having to know the details. Developers are free to focus on their code instead of spending time writing Dockerfiles and running docker builds.

Both Developers and Operators communicate with the OpenShift Platform via one of the following methods:

* **Command Line Interface** - The command line tool that we will be using as part of this training is called the *oc* tool. You used this briefly
in the last scenario. This tool is written in the Go programming language and is a single executable that is provided for
Windows, OS X, and the Linux Operating Systems.
* **Web Console** -  OpenShift also provides a feature rich Web Console that provides a friendly graphical interface for interacting with the platform.
* **REST API** - Both the command line tool and the web console actually communicate to OpenShift via the same method, the REST API.  Having a robust API allows users to create their own scripts and automation depending on their specific requirements.  For detailed information about the REST API, check out the [official documentation](https://docs.openshift.org/latest/rest_api/index.html).
You will not use the REST API directly in this workshop.

During this workshop, you will be using both the command line tool and the web console. However, it should be noted that there are plugins for several integrated development environments as well. For example, to use OpenShift from the Eclipse IDE, you would want to use the official [JBoss Tools](https://tools.jboss.org/features/openshift.html) plugin.

Now that you know how to interact with OpenShift, let's focus on some core concepts that you as a developer will need to understand as you are building your applications!

## Verifying the Dev Environment

In the previous lab you created a new OpenShift project called `userXX-coolstore-dev` which represents your developer personal project in which you deployed the CoolStore monolith.

**1. Verify Application**

Let's take a moment and review the OpenShift resources that are created for the Monolith:

* Build Config: **coolstore** build config is the configuration for building the Monolith
image from the source code or WAR file
* Image Stream: **coolstore** image stream is the virtual view of all coolstore container
images built and pushed to the OpenShift integrated registry.
* Deployment Config: **coolstore** deployment config deploys and redeploys the Coolstore container
image whenever a new coolstore container image becomes available. Similarly, the **coolstore-postgresql**
does the same for the database.
* Service: **coolstore** and **coolstore-postgresql** service is an internal load balancer which identifies a set of
pods (containers) in order to proxy the connections it receives to them. Backing pods can be
added to or removed from a service arbitrarily while the service remains consistently available,
enabling anything that depends on the service to refer to it at a consistent address (service name
or IP).
* Route: **www** route registers the service on the built-in external load-balancer
and assigns a public DNS name to it so that it can be reached from outside OpenShift cluster.

You can review the above resources in the OpenShift Web Console or using the `oc get` or `oc describe` commands (`oc describe` gives more detailed info):

> You can use short synonyms for long words, like `bc` instead of `buildconfig`, and `is` for `imagestream`, `dc` for `deploymentconfig`, `svc` for service, etc.

> **NOTE**: Don't worry about reading and understanding the output of `oc describe`. Just make sure the command doesn't report errors!

Run these commands to inspect the elements:

~~~sh
oc get bc coolstore

oc get is coolstore

oc get dc coolstore

oc get svc coolstore

oc describe route www
~~~

Verify that you can access the monolith by clicking on the exposed OpenShift route at  `http://www-userXX-coolstore-dev.{{ROUTE_SUFFIX}}` to open up the sample application in a separate browser tab.

You should also be able to see both the CoolStore monolith and its database running in separate pods:

`oc get pods -l application=coolstore`

The output should look like this:

~~~sh
NAME                           READY     STATUS    RESTARTS   AGE
coolstore-2-bpkkc              1/1       Running   0          4m
coolstore-postgresql-1-jpcb8   1/1       Running   0          9m
~~~

**1. Verify Database**

You can log into the running Postgres container using the following:

`oc  rsh dc/coolstore-postgresql`

Once logged in, use the following command to execute an SQL statement to show some content from the database:

`psql -U $POSTGRESQL_USER $POSTGRESQL_DATABASE -c 'select name from PRODUCT_CATALOG;'`

You should see the following:

~~~sh
          name
------------------------
 Red Fedora
 Forge Laptop Sticker
 Solid Performance Polo
 Ogio Caliber Polo
 16 oz. Vortex Tumbler
 Atari 2600 Joystick
 Pebble Smart Watch
 Oculus Rift
 Lytro Camera
(9 rows)
~~~

Don't forget to exit the pod's shell with `exit`

With our running project on OpenShift, in the next step we'll explore how you as a developer can work with the running app to make changes and debug the application!

## Making Changes to Containers

In this step you will learn how to transfer files between your local machine and a running container.

One of the properties of container images is that they are **immutable**. That is, although you can make changes to the local container filesystem of a running image, the changes are _not permanent_. When that container is stopped, _any changes are discarded_. When a new container is started from the same container image, it _reverts back_ to what was originally built into the image.

Although any changes to the local container filesystem are discarded when the container is stopped, it can sometimes be convenient to be able to upload files into a running container. One example of where this might be done is during development and a dynamic scripting language like javascript or static content files like html is being used. By being able to modify code in the container, you can modify the application to test changes before rebuilding the image.

In addition to uploading files into a running container, you might also want to be able to download files. During development these may be data files or log files created by the application.

### Live Synchronization of Project Files

In addition to being able to manually upload or download files when you choose to, the ``oc rsync`` command can also be set up to perform live synchronization of files between your local computer and the container. When there is a change to a file, the changed file will be automatically copied up to the container.

This same process can also be run in the opposite direction if required, with changes made in the container being automatically copied back to your local computer.

An example of where it can be useful to have changes automatically copied from your local computer into the container is during the development of an application.

For scripted programming languages such as JavaScript, PHP, Python or Ruby, where no separate compilation phase is required you can perform live code development with your application running inside of OpenShift.

For JBoss EAP applications you can sync individual files (such as HTML/CSS/JS files), or sync entire application .WAR files. It's more challenging to synchronize individual files as it requires that you use an *exploded* archive deployment, so the use of [JBoss Developer Studio](https://developers.redhat.com/products/devstudio/overview/) is recommended, which automates this process (see [these docs](https://tools.jboss.org/features/livereload.html) for more info).

For this workshop, we'll Live synchronize the entire WAR file.

First, click on the Coolstore application link at 

`http://www-coolstore-dev.{{ROUTE_SUFFIX}}` to open the application in a browser tab so you can watch changes.

**1. Turn on Live Sync**

Export Coolstore Pod name:

~~~sh
export COOLSTORE_DEV_POD_NAME=$(oc get pods --output='name' -l deploymentConfig=coolstore | cut -c 5-)
~~~

Turn on **Live sync** by executing this command:

`oc  rsync deployments/ $COOLSTORE_DEV_POD_NAME:/deployments --watch --no-perms &`

> The `&` character at the end places the command into the background. We will kill it at the end of this step.

Now `oc` is watching the `deployments/` directory for changes to the `ROOT.war` file. Anytime that file changes,
`oc` will copy it into the running container and we should see the changes immediately (or after a few seconds). This is
much faster than waiting for a full re-build and re-deploy of the container image.

**2. Make a change to the UI**

Next, let's make a change to the app that will be obvious in the UI.

First, open `src/main/webapp/app/css/coolstore.css`, which contains the CSS stylesheet for the
CoolStore app.

Add the following CSS to turn the header bar background to Red Hat red :

~~~css
.navbar-header {
    background: #CC0000
}
~~~

**2. Rebuild application For RED background**

Let's re-build the application using the command `build-eap-openshift` in the command palette. In the tab **sync-eap-openshift** you should see the following :

~~~sh
sent 65 bytes  received 12 bytes  51.33 bytes/sec
total size is 14,653,352  speedup is 190,303.27
~~~

This will update the ROOT.war file and cause the application to change.

Re-visit the app by reloading the Coolstore webpage (or clicking again on the Coolstore application link at : `http://www-userXX-coolstore-dev.{{ROUTE_SUFFIX}}`

You should now see the red header:

> **NOTE** If you don't see the red header, you may need to do a full reload of the webpage.
On Windows/Linux press `CTRL`+`F5` or hold down `SHIFT` and press the Reload button, or try
`CTRL`+`SHIFT`+`F5`. On Mac OS X, press `SHIFT`+`CMD`+`R`, or hold `SHIFT` while pressing the
Reload button.

![Red]({% image_path developer-intro/nav-red.png %}){:width="80%"}

**3. Rebuild again for BLUE background**

Repeat the process, but replace the background color to be blue (click **Copy to Editor** to replace `#CC0000` with `blue`):

~~~css
background: blue
~~~

Again, re-build the app:

~~~sh
mvn package -Popenshift
~~~

or use the command `build-eap-openshift` in the command palette.

This will update the ROOT.war file again and cause the application to change.

Re-visit the app by reloading the Coolstore webpage (or clicking again on the Coolstore application link at 

`http://www-userXX-coolstore-dev.{{ROUTE_SUFFIX}})`.

![Blue]({% image_path developer-intro/nav-blue.png %}){:width="80%"}

It's blue! You can do this as many times as you wish, which is great for speedy development and testing.

We'll leave the blue header for the moment, but will change it back to the original color soon.

Because we used `oc rsync` to quickly re-deploy changes to the running pod, the changes will be lost if we restart the pod. Let's update the container image
to contain our new blue header. Execute:

`oc start-build coolstore --from-file=deployments/ROOT.war`

or use the command `deploy-eap-openshift` in the command palette. And again, wait for it to complete.

## Before continuing

Kill the `oc rsync` processes we started earlier in the background. Execute:

`kill %1` or close the tab sync-eap-openshift

On to the next challenge!

## Deploying the Production Environment

In the previous scenarios, you deployed the Coolstore monolith using an OpenShift Template into the `userXX-coolstore-dev` Project. The template created the necessary objects (BuildConfig, DeploymentConfig, ImageStreams, Services, and Routes) and gave you as a Developer a "playground" in which to run the app, make changes and debug.

In this step we are now going to setup a separate production environment and explore some best practices and techniques for developers and DevOps teams for getting code from the developer (that's YOU!) to production with less downtime and greater consistency.

## Prod vs. Dev

The existing `userXX-coolstore-dev` project is used as a developer environment for building new versions of the app after code changes and deploying them to the development environment.

In a real project on OpenShift, _dev_, _test_ and _production_ environments would typically use different OpenShift projects and perhaps even different OpenShift clusters.

For simplicity in this scenario we will only use a _dev_ and _prod_ environment, and no test/QA environment.

## Create the production environment

We will create and initialize the new production environment using another template in a separate OpenShift project.

**1. Initialize production project environment**

Execute the following `oc` command to create a new project:

`oc new-project userXX-coolstore-prod --display-name='Coolstore Monolith - Production'`

This will create a new OpenShift project called `userXX-coolstore-prod` from which our production application will run.

**2. Add the production elements**

In this case we'll use the production template to create the objects. Execute:

`oc new-app --template=coolstore-monolith-pipeline-build`

This will use an OpenShift Template called `coolstore-monolith-pipeline-build` to construct the production application. As you probably guessed it will also include a Jenkins Pipeline to control the production application (more on this later!)

Navigate to the Web Console to see your new app and the components using this link:

* Coolstore Prod Project Overview at 

`https://{{OPENSHIFT_MASTER}}/console/project/userXX-coolstore-prod/overview`

![Prod]({% image_path developer-intro/coolstore-prod-overview.png %}){:width="80%"}

You can see the production database, and an application called _Jenkins_ which OpenShift uses to manage CI/CD pipeline deployments. There is no running production app just yet. The only running app is back in the _dev_ environment, where you used a binary build to run the app previously.

In the next step, we'll _promote_ the app from the _dev_ environment to the _production_ environment using an OpenShift pipeline build. Let's get going!

## Promoting Apps Across Environments with Pipelines

#### Continuous Delivery
So far you have built and deployed the app manually to OpenShift in the _dev_ environment. Although it's convenient for local development, it's an error-prone way of delivering software when extended to test and production environments.

Continuous Delivery (CD) refers to a set of practices with the intention of automating  various aspects of delivery software. One of these practices is called delivery pipeline  which is an automated process to define the steps a change in code or configuration has to go through in order to reach upper environments and eventually to production. 

OpenShift simplifies building CI/CD Pipelines by integrating the popular [Jenkins pipelines](https://jenkins.io/doc/book/pipeline/overview/) into the platform and enables defining truly complex workflows directly from within OpenShift.

The first step for any deployment pipeline is to store all code and configurations in  a source code repository. In this workshop, the source code and configurations are stored in a GitHub repository we've been using at [https://github.com/clerixmaxime/modernize-apps-labs]. This repository has been copied locally to your environment and you've been using it ever since!

#### Pipelines

OpenShift has built-in support for CI/CD pipelines by allowing developers to define a [Jenkins pipeline](https://jenkins.io/solutions/pipeline/) for execution by a Jenkins automation engine, which is automatically provisioned on-demand by OpenShift when needed.

The build can get started, monitored, and managed by OpenShift in the same way as any other build types e.g. S2I. Pipeline workflows are defined in a Jenkinsfile, either embedded directly in the build configuration, or supplied in a Git repository and referenced by the build configuration. They are written using the [Groovy scripting language](http://groovy-lang.org/).

As part of the production environment template you used in the last step, a Pipeline build object was created. Ordinarily the pipeline would contain steps to build the project in the _dev_ environment, store the resulting image in the local repository, run the image and execute tests against it, then wait for human approval to _promote_ the resulting image to other environments like test or production.

**1. Inspect the Pipeline Definition**

Our pipeline is somewhat simplified for the purposes of this Workshop. Inspect the contents of the pipeline using the following command:

`oc describe bc/monolith-pipeline`

You can see the Jenkinsfile definition of the pipeline in the output:

~~~groovy
  node ('maven') {
    stage 'Build'
    sleep 5

    stage 'Run Tests in DEV'
    sleep 10

    stage 'Deploy to PROD'
    openshiftTag(sourceStream: 'coolstore', sourceTag: 'latest', namespace: 'userXX-coolstore-dev', destinationStream: 'coolstore', destinationTag: 'prod', destinationNamespace: 'userXX-coolstore-prod')
    sleep 10

    stage 'Run Tests in PROD'
    sleep 30
  }
~~~

> /!\ You have to replace `userXX` by your own `userID` when using the openshiftTag() method. Use the following command `oc edit bc/monolith-pipeline` to edit your pipeline

Pipeline syntax allows creating complex deployment scenarios with the possibility of defining checkpoint for manual interaction and approval process using [the large set of steps and plugins that Jenkins provides](https://jenkins.io/doc/pipeline/steps/) in order to adapt the pipeline to the process used in your team. You can see a few examples of advanced pipelines in the [OpenShift GitHub Repository](https://github.com/openshift/origin/tree/master/examples/jenkins/pipeline) or [here](https://github.com/demo-redhat-forum-2018/monolith/blob/step-2/Jenkinsfile).

To simplify the pipeline in this workshop, we simulate the build and tests and skip any need for human input. Once the pipeline completes, it deploys the app from the _dev_ environment to our _production_ environment using the above `openshiftTag()` method, which simply re-tags the image you already created using a tag which will trigger deployment in the production environment.

**2. Promote the dev image to production using the pipeline**

You can use the _oc_ command line to invoke the build pipeline, or the Web Console. Let's use the Web Console. Open the production project in the web console:

* Web Console - Coolstore Monolith Prod at 

`https://{{OPENSHIFT_MASTER}}/console/project/userXX-coolstore-prod`

Next, navigate to _Builds -> Pipelines_ and click __Start Pipeline__ next to the `coolstore-monolith` pipeline:

![Prod]({% image_path developer-intro/pipe-start.png %}){:width="80%"}

This will start the pipeline. **It will take a minute or two to start the pipeline** (future runs will not
take as much time as the Jenkins infrastructure will already be warmed up). You can watch the progress of the pipeline:

![Prod]({% image_path developer-intro/pipe-prog.png %}){:width="80%"}

Once the pipeline completes, return to the Prod Project Overview at 

`https://{{OPENSHIFT_MASTER}}/console/project/userXX-coolstore-prod`
and notice that the application is now deployed and running!

![Prod]({% image_path developer-intro/pipe-done.png %}){:width="80%"}

View the production app **with the blue header from before** is running by clicking: CoolStore Production App at 

`http://www-userXX-coolstore-prod.{{ROUTE_SUFFIX}}` (it may take
a few moments for the container to deploy fully.)

## Congratulations!

You have successfully setup a development and production environment for your project and can use this workflow for future projects as well.

In the final step we'll add a human interaction element to the pipeline, so that you as a project lead can be in charge of approving changes.

## More Reading

* [OpenShift Pipeline Documentation](https://docs.openshift.com/container-platform/latest/dev_guide/dev_tutorials/openshift_pipeline.html)


## Adding Pipeline Approval Steps (OPTIONAL, you can directly go to the next section)

In previous steps you used an OpenShift Pipeline to automate the process of building and deploying changes from the dev environment to production.

In this step, we'll add a final checkpoint to the pipeline which will require you as the project lead to approve the final push to production.

**1. Edit the pipeline**

Ordinarily your pipeline definition would be checked into a source code management system like Git, and to change the pipeline you'd edit the _Jenkinsfile_ in the source base. For this workshop we'll just edit it directly to add the necessary changes. You can edit it with the `oc` command but we'll use the Web Console.

Open the `monolith-pipeline` configuration page in the Web Console (you can navigate to it from _Builds -> Pipelines_ but here's a quick link):

* Pipeline Config page at 

`https://{{OPENSHIFT_MASTER}}/console/project/userXX-coolstore-prod/browse/pipelines/monolith-pipeline?tab=configuration`

On this page you can see the pipeline definition. Click _Actions -> Edit_ to edit the pipeline:

![Prod]({% image_path developer-intro/pipe-edit.png %}){:width="80%"}

In the pipeline definition editor, add a new stage to the pipeline, just before the `Deploy to PROD` step:

> **NOTE**: You will need to copy and paste the below code into the right place as shown in the below image.

~~~groovy
  stage 'Approve Go Live'
  timeout(time:30, unit:'MINUTES') {
    input message:'Go Live in Production (switch to new version)?'
  }
~~~

Your final pipeline should look like:

![Prod]({% image_path developer-intro/pipe-edit2.png %}){:width="80%"}

Click **Save**.

**2. Make a simple change to the app**

With the approval step in place, let's simulate a new change from a developer who wants to change the color of the header in the coolstore back to the original (black) color. Revert the changes that you previously made to the file `src/main/webapp/app/css/coolstore.css` by removing the following section:

~~~css
.navbar-header {
    background: #CC0000
}
~~~

Next, re-build the app once more:

~~~sh
mvn clean package -Popenshift
~~~~

or use the command `build-eap-openshift` in the command palette.

And re-deploy it to the dev environment using a binary build just as we did before:

~~~sh
oc start-build -n coolstore-dev coolstore --from-file=deployments/ROOT.war
~~~~

or use the command `deploy-eap-openshift` in the command palette.

And verify that the original black header is visible in the dev application:

* Coolstore - Dev at 

`http://www-userXX-coolstore-dev.{{ROUTE_SUFFIX}}`

![Prod]({% image_path developer-intro/pipe-orig.png %}){:width="60%"}

While the production application is still blue:

* Coolstore - Prod at 

`http://www-userXX-coolstore-prod.{{ROUTE_SUFFIX}}`

![Prod]({% image_path developer-intro/nav-blue.png %}){:width="80%"}

We're happy with this change in dev, so let's promote the new change to prod, using the new approval step!

**3. Run the pipeline again**

Invoke the pipeline once more by clicking **Start Pipeline** on the Pipeline Config page at 

`https://{{OPENSHIFT_MASTER}}/console/project/coolstore-prod/browse/pipelines/monolith-pipeline`

The same pipeline progress will be shown, however before deploying to prod, you will see a prompt in the pipeline:

![Prod]({% image_path developer-intro/pipe-prompt.png %}){:width="80%"}

Click on the link for `Input Required`. This will open a new tab and direct you to Jenkins itself, where you can login with
the same credentials as OpenShift:

* Username: `userXX`
* Password: `openshift`

Accept the browser certificate warning and the Jenkins/OpenShift permissions, and then you will find yourself at the approval prompt:

![Prod]({% image_path developer-intro/pipe-jenkins-prompt.png %}){:width="80%"}

**3. Approve the change to go live**

Click **Proceed**, which will approve the change to be pushed to production. You could also have
clicked **Abort** which would stop the pipeline immediately in case the change was unwanted or unapproved.

Once you click **Proceed**, you will see the log file from Jenkins showing the final progress and deployment.

Wait for the production deployment to complete:

`oc rollout -n userXX-coolstore-prod status dc/coolstore-prod`

Once it completes, verify that the production application has the new change (original black header):

* Coolstore - Prod at 

`http://www-userXX-coolstore-prod.{{ROUTE_SUFFIX}}`

![Prod]({% image_path developer-intro/pipe-orig.png %}){:width="60%"}

## Congratulations!

You have added a human approval step for all future developer changes. You now have two projects that can be visualized as:

![Prod]({% image_path developer-intro/goal.png %}){:width="80%"}

## Summary

In this scenario you learned how to use the OpenShift Container Platform as a developer to build, and deploy applications. You also learned how OpenShift makes your life easier as a developer, architect, and DevOps engineer.

You can use these techniques in future projects to modernize your existing applications and add a lot of functionality without major re-writes.

The monolithic application we have been using so far works great, but is starting to show its age. Even small changes to one part of the app require many teams to be involved in the push to production.

In the next few scenarios we will start to modernize our application and begin to move away from monolithic architectures and toward microservice-style architectures using Red Hat technology. Let\'s go!