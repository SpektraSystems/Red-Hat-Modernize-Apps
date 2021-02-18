# SCENARIO 4: Transforming an existing monolith (Part 2)

* Purpose: Showing developers and architects how Red Hat jumpstarts modernization
* Difficulty: `intermediate`
* Time: `60-70 minutes`

## Intro
In the previous scenarios, you learned how to take an existing monolithic app and refactor a single _inventory_ service using Quarkus. Since Quarkus is using Java EE much of the technology from the monolith can be reused directly, like JPA and JAX-RS. The previous scenario resulted in you creating an inventory service, but so far we haven't started _strangling_ the monolith. That is because the inventory service is never called directly by the UI. It's a backend service that is only used only by other backend services. In this scenario, you will create the catalog service and the catalog service will call the inventory service. When you are ready, you will change the route to tie the UI calls to new service.

To implement this, we are going to use the Spring Framework. The reason for using Spring for this service is to introduce you to Spring Development, and how [Red Hat Runtimes](https://www.redhat.com/en/products/runtimes) helps to make Spring development on Kubernetes easy. In real life, the reason for choosing Spring vs. WF Swarm mostly depends on personal preferences, like existing knowledge, etc. At the core Spring and Java EE are very similar.

The goal is to produce something like:

<kbd>![](images/AROLatestImages/ImageCatalog.JPG)</kbd>

## What is Spring Framework?

Spring is one of the most popular Java Frameworks and offers an alternative to the Java EE programming model. Spring is also very popular for building applications based on microservices architectures. Spring Boot is a popular tool in the Spring ecosystem that helps with organizing and using 3rd-party libraries together with Spring and also provides a mechanism for boot strapping embeddable runtimes, like Apache Tomcat. Bootable applications (sometimes also called _fat jars_) fits the container model very well since in a container platform like OpenShift responsibilities like starting, stopping and monitoring applications are then handled by the container platform instead of an Application Server.

## Aggregate microservices calls
Another thing you will learn in this scenario is one of the techniques to aggregate services using service-to-service calls. Other possible solutions would be to use a microservices gateway or combine services using client-side logic.

## Setup for Exercise

To start in the right directory, from the CodeReady Workspaces Terminal, run the following command:

~~~sh
cd /projects/modernize-apps/catalog
~~~

## Examine the sample project

For your convenience, this scenario has been created with a base project using the Java programming language and the Apache Maven build tool.

Initially, the project is almost empty and doesn't do anything. Start by reviewing the content in the file explorer.

The output should look something like this

<kbd>![](images/AROLatestImages/catalogtree.jpg)</kbd>

As you can see, there are some files that we have prepared for you in the project. Under `src/main/resources/static/index.html` we have for example prepared a simple html-based UI file for you. Except for the `fabric8/` folder and `index.html`, this matches very well what you would get if you generated an empty project from the [Spring Initializr](https://start.spring.io) web page. For the moment you can ignore the content of the `fabric8/` folder (we will discuss this later).

One that differs slightly is the `pom.xml`. Please open the and examine it a bit closer (but do not change anything at this time)

As you review the content, you will notice that there are a lot of **TODO** comments. **Do not remove them!** These comments are used as a marker and without them, you will not be able to finish this scenario.

Notice that we are not using the default BOM (Bill of material) that Spring Boot projects typically use. Instead, we are using a BOM provided by Red Hat.

~~~xml
<dependencyManagement>
    <dependencies>
    <dependency>
        <groupId>me.snowdrop</groupId>
        <artifactId>spring-boot-bom</artifactId>
        <version>${spring-boot.bom.version}</version>
        <type>pom</type>
        <scope>import</scope>
    </dependency>
    </dependencies>
</dependencyManagement>
~~~

We use this bill of material to make sure that we are using the version of for example Apache Tomcat that Red Hat supports.

**Adding web (Apache Tomcat) to the application**

Since our applications (like most) will be a web application, we need to use a servlet container like Apache Tomcat or Undertow. Since Red Hat offers support for Apache Tomcat (e.g., security patches, bug fixes, etc.), we will use it.

> **NOTE:** Undertow is another an open source project that is maintained by Red Hat and therefore Red Hat plans to add support for Undertow shortly.

To add Apache Tomcat to our project all we have to do is to add the following lines in ``modernize-apps/catalog/pom.xml``. Open the file to automatically add these lines at the `<!-- TODO: Add web (tomcat) dependency here -->` marker:

~~~xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
~~~

We will also make use of Spring's JDBC implementation, so we need to add the following to `pom.xml` at the `<!-- TODO: Add data jpa dependency here -->` marker:

~~~xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jdbc</artifactId>
    </dependency>
~~~

We will go ahead and add a bunch of other dependencies while we have the pom.xml open. These will be explained later. Add these at the
`<!-- TODO: Add actuator, feign and hystrix dependency here -->` marker:

~~~xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
    </dependency>
    <dependency>
        <groupId>org.json</groupId>
        <artifactId>json</artifactId>
        <version>20180813</version>
    </dependency>


~~~

**Test the application locally**

As we develop the application, we might want to test and verify our change at different stages. We can do that locally, by using the `spring-boot` maven plugin.

Run the application by executing the below command:

`mvn spring-boot:run`

Wait for it to complete startup and report Started RestApplication in ***** seconds (JVM running for ******)

**3. Verify the application**

In the CodeReady workspace open a new terminal and run the below command:
```
curl http://localhost:8081

```
You should now see the html page HTML.

> **NOTE:** The service calls to get products from the catalog doesn't work yet. Be patient! We will work on it in the next steps.

**4. Stop the application**

Before moving on, press `CTRL-C` on your terminal window to stop the application.
## Congratulations

You have now successfully executed the first step in this scenario.

Now you've seen how to get started with Spring Boot development on Red Hat Runtimes.

In next step of this scenario, we will add the logic to be able to read a list of fruits from the database.

## Create Domain Objects


## Implement the database repository

We are now ready to implement the database repository.

Create the file ``modernize-apps/catalog/src/main/java/com/redhat/coolstore/service/ProductRepository.java``.

Here is the base for the calls, insert the following code:

~~~java
package com.redhat.coolstore.service;

import java.util.List;

import com.redhat.coolstore.model.Product;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

@Repository
public class ProductRepository {

//TODO: Autowire the jdbcTemplate here

//TODO: Add row mapper here

//TODO: Create a method for returning all products

//TODO: Create a method for returning one product

}
~~~

> NOTE: That the class is annotated with `@Repository`. This is a feature of Spring that makes it possible to avoid a lot of boiler plate code and only write the implementation details for this data repository. It also makes it very easy to switch to another data storage, like a NoSQL database.

Spring Data provides a convenient way for us to access data without having to write a lot of boiler plate code. One way to do that is to use a `JdbcTemplate`. First we need to autowire that as a member to `ProductRepository`. Copy and paste the following code under the comment `//TODO: Autowire the jdbcTemplate here`:

~~~java
@Autowired
private JdbcTemplate jdbcTemplate;
~~~

The `JdbcTemplate` require that we provide a `RowMapper`so that it can map between rows in the query to Java Objects. We are going to define the `RowMapper` like this:
The `JdbcTemplate` require that we provide a `RowMapper` so that it can map between rows in the query to Java Objects. We are going to define the `RowMapper` like this (copy and paste the following code under the comment `//TODO: Add row mapper here`):

~~~java
private RowMapper<Product> rowMapper = (rs, rowNum) -> new Product(
        rs.getString("itemId"),
        rs.getString("name"),
        rs.getString("description"),
        rs.getDouble("price"));
~~~

Now we are ready to create the methods. Let's start with the `readAll()`. It should return a `List<Product>` and then we can write the query as `SELECT * FROM catalog` and use the rowMapper to map that into `Product` objects. Our method should look like this (copy and paste the following code under the comment `//TODO: Create a method for returning all products`):

~~~java
public List<Product> readAll() {
    return jdbcTemplate.query("SELECT * FROM catalog", rowMapper);
}
~~~

The implementation of the method using the `JdbcTemplate` and `RowMapper` return the Product (copy and paste the following code under the comment `//TODO: Create a method for returning one product`):

~~~java
public Product findById(String id) {
    return jdbcTemplate.queryForObject("SELECT * FROM catalog WHERE itemId = '" + id + "'", rowMapper);
}
~~~

The `ProductRepository` should now have all the components, but we still need to tell spring how to connect to the database. For local development we will use the H2 in-memory database. When deploying this to OpenShift we are instead going to use the PostgreSQL database, which matches what we are using in production.

The Spring Framework has a lot of sane defaults that can always seem magical sometimes, but basically all we have todo to setup the database driver is to provide some configuration values. Open ``modernize-apps/catalog/src/main/resources/application-default.properties`` and add the following properties where the comment says "#TODO: Add database properties"
Add the following:

~~~java
spring.datasource.url=jdbc:h2:mem:catalog;DB_CLOSE_ON_EXIT=FALSE
spring.datasource.username=sa
spring.datasource.password=sa
spring.datasource.driver-class-name=org.h2.Driver
~~~

The Spring Data framework will automatically see if there is a schema.sql in the class path and run that when initializing.

In next step of this scenario, we will add the logic to expose the database content from REST endpoints using JSON format.

## Create Catalog Service

Now you are going to create a service class. Later on the service class will be the one that controls the interaction with the inventory service, but for now it's basically just a wrapper of the repository class.

Create a new class `CatalogService` with the following path ``modernize-apps/catalog/src/main/java/com/redhat/coolstore/service/CatalogService.java``

And then Open the file to implement the new service:

~~~java
package com.redhat.coolstore.service;

import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

//import com.redhat.coolstore.client.InventoryClient;
import com.redhat.coolstore.model.Product;
import org.json.JSONArray;
import org.json.JSONObject;

@Service
public class CatalogService {

    @Autowired
    private ProductRepository repository;

    //TODO: Autowire Inventory Client

    public Product read(String id) {
        Product product = repository.findById(id);
        //TODO: Update the quantity for the product by calling the Inventory service
        return product;
    }

    public List<Product> readAll() {
        List<Product> productList = repository.readAll();
        //TODO: Update the quantity for the products by calling the Inventory service
        return productList;
    }

    //TODO: Add Callback Factory Component

}
~~~

As you can see there is a number of **TODO** in the code, and later we will use these placeholders to add logic for calling the Inventory Client to get the quantity. However for the moment we will ignore these placeholders.

Now we are ready to implement the `CatalogEndpoint`.

Start by creating the file by opening: ``modernize-apps/catalog/src/main/java/com/redhat/coolstore/service/CatalogEndpoint.java``

Then add the following content:

~~~java
package com.redhat.coolstore.service;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.redhat.coolstore.model.Product;

@RestController
@RequestMapping("/services")
public class CatalogEndpoint {
    private final CatalogService catalogService;

    public CatalogEndpoint(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/products")
    public List<Product> readAll() {
        return this.catalogService.readAll();
    }

    @GetMapping("/product/{id}")
    public Product read(@PathVariable("id") String id) {
        return this.catalogService.read(id);
    }
}
~~~

The Spring MVC Framework uses Jackson by default to serialize or map Java objects to JSON and vice versa. Because Jackson extends upon JAXB and can automatically parse simple Java structures and parse them into JSON and vice verse and since our `Product.java` is very simple and only contains basic attributes we do not need to tell Jackson how to parse between object and JSON.

Since we now have endpoints that returns the catalog we can also start the service and load the default page again, which should now return the products.

Start the application by running the following command:

~~~sh
mvn spring-boot:run
~~~~

Once the application is live, you will get a pop-up in the bottom-right corner of the terminal. Click on **Yes** button to get the link of the application

<kbd>![](images/AROLatestImages/cataloglinkyes.jpg)</kbd>

Then, click on **Open Link** to open the application

<kbd>![](images/AROLatestImages/catalogopenlink.jpg)</kbd>


Or, we can verify the endpoint by running the following command in a new terminal (Note the link below will execute in a second terminal)

``curl http://localhost:8081/services/products ; echo``

You should get a full JSON array consisting of all the products:

~~~json
[{"itemId":"329299","name":"Red Fedora","desc":"Official Red Hat Fedora","price":34.99,"quantity":0},{"itemId":"329199","name":"Forge Laptop Sticker"},
...
]
~~~

You have now successfully executed the third step in this scenario.

Now you've seen how to create REST application in Spring MVC and create a simple application that returns product.

In the next scenario we will also call another service to enrich the endpoint response with inventory status.

### Before moving on

Be sure to stop the service by clicking on the first Terminal window and typing `CTRL-C`.

## Congratulations!

Next, we'll add a call to the existing Inventory service to enrich the above data with Inventory information. On to the next challenge!

## Get inventory data

So far our application has been kind of straight forward, but our monolith code for the catalog is also returning the inventory status. In the monolith since both the inventory data and catalog data is in the same database we used a OneToOne mapping in JPA like this:

~~~java
@OneToOne(cascade = CascadeType.ALL,fetch=FetchType.EAGER)
@PrimaryKeyJoinColumn
private InventoryEntity inventory;
~~~

When redesigning our application to Microservices using domain driven design we have identified that Inventory and ProductCatalog are two separate domains. However our current UI expects to retrieve data from both the Catalog Service and Inventory service in a singe request.

**Service interaction**

Our problem is that the user interface requires data from two services when calling the REST service on `/services/products`. There are multiple ways to solve this like:

1. **Client Side integration** - We could extend our UI to first call `/services/products` and then for each product item call `/services/inventory/{prodId}` to get the inventory status and then combine the result in the web browser. This would be the least intrusive method, but it also means that if we have 100 of products, the client will make 101 request to the server. If we have a slow internet connection this may cause issues.
2. **Microservices Gateway** - Creating a gateway in-front of the `Catalog Service` that first calls the Catalog Service and then based on the response calls the inventory is another option. This way we can avoid lots of calls from the client to the server. Apache Camel provides nice capabilities to do this and if you are interested to learn more about this, please checkout the Coolstore Microservices example [here](http://github.com/jbossdemocentral/coolstore-microservice).
3. **Service-to-Service** - Depending on use-case and preferences another solution would be to do service-to-service calls instead. In our case means that the Catalog Service would call the Inventory service using REST to retrieve the inventory status and include that in the response.

There are no right or wrong answers here, but since this is a workshop on application modernization using Red Hat Runtimes, we will not choose option 1 or 2 here. Instead we are going to use option 3 and extend our Catalog to call the Inventory service.
**Implementing the Inventory Client**

Since we now have a nice way to test our service-to-service interaction we can now create the client that calls the Inventory. Netflix has provided some nice extensions to the Spring Framework that are mostly captured in the Spring Cloud project, however Spring Cloud is mainly focused on Pivotal Cloud Foundry and because of that Red Hat and others have contributed Spring Cloud Kubernetes to the Spring Cloud project, which enables the same functionallity for Kubernetes based platforms like OpenShift.

The inventory client will use a Netflix project called _Feign_, which provides a nice way to avoid having to write boilerplate code. Feign also integrate with Hystrix which gives us capability for circuit breaking. We will discuss this more later, but let's start with the implementation of the Inventory Client. Using Feign all we have to do is to create a interface that details which parameters and return type we expect, annotate it with `@RequestMapping` and provide some details and then annotate the interface with `@Feign` and provide it with a name.

Create the file : ``modernize-apps/catalog/src/main/java/com/redhat/coolstore/client/InventoryClient.java``

Add the following small code to the file:

~~~java
package com.redhat.coolstore.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import com.redhat.coolstore.model.Inventory;
import feign.hystrix.FallbackFactory;

@FeignClient(name="inventory")
public interface InventoryClient {
    @GetMapping(path = "/services/inventory/{itemId}", consumes = {MediaType.APPLICATION_JSON_VALUE})
    String getInventoryStatus(@PathVariable("itemId") String itemId);

//TODO: Add Fallback factory here
}
~~~

There is one more thing that we need to do which is to tell Feign where the inventory service is running. Before that notice that we are setting the `@FeignClient(name="inventory")`.

Open ``modernize-apps/catalog/src/main/resources/application-default.properties`` and add these properties below the `#TODO: Configure netflix libraries` marker:

~~~java
inventory.ribbon.listOfServers=inventory:8080
feign.hystrix.enabled=true
~~~

By setting `inventory.ribbon.listOfServers` we are hard coding the actual URL of the service to `inventory:8080`. If we had multiple servers we could also add those using a comma. However using Kubernetes there is no need to have multiple endpoints listed here since Kubernetes has a concept of _Services_ that will internally route between multiple instances of the same service. Later on we will update this value to reflect our URL when deploying to OpenShift.


Now that we have a client we can make use of it in our `CatalogService`

Open ``modernize-apps/catalog/src/main/java/com/redhat/coolstore/service/CatalogService.java``

And autowire (e.g. inject) the client into it by inserting this at the `//TODO: Autowire Inventory Client` marker:

~~~java
@Autowired
private InventoryClient inventoryClient;
~~~

Next, update the `read(String id)` method at the comment `//TODO: Update the quantity for the product by calling the Inventory service` add the following:

~~~java
JSONArray jsonArray = new JSONArray(inventoryClient.getInventoryStatus(product.getItemId()));
List<String> quantity = IntStream.range(0, jsonArray.length())
    .mapToObj(index -> ((JSONObject)jsonArray.get(index))
    .optString("quantity")).collect(Collectors.toList());
product.setQuantity(Integer.parseInt(quantity.get(0)));
~~~

Also, don't forget to add the import statement by un-commenting the import statement `//import com.redhat.coolstore.client.InventoryClient` near the top

~~~java
import com.redhat.coolstore.client.InventoryClient;
~~~

Also in the `readAll()` method replace the comment `//TODO: Update the quantity for the products by calling the Inventory service` with the following:

~~~java
productList.forEach(p -> {
    JSONArray jsonArray = new JSONArray(this.inventoryClient.getInventoryStatus(p.getItemId()));
    List<String> quantity = IntStream.range(0, jsonArray.length())
      .mapToObj(index -> ((JSONObject)jsonArray.get(index))
      .optString("quantity")).collect(Collectors.toList());
    p.setQuantity(Integer.parseInt(quantity.get(0)));
});
~~~

## Create a fallback for inventory

In the previous step we added a client to call the Inventory service. Services calling services is a common practice in Microservices Architecture, but as we add more and more services the likelihood of a problem increases dramatically. Even if each service has 99.9% update, if we have 100 of services our estimated up time will only be ~90%. We therefor need to plan for failures to happen and our application logic has to consider that dependent services are not responding.

In the previous step we used the Feign client from the Netflix cloud native libraries to avoid having to write boilerplate code for doing a REST call. However Feign also have another good property which is that we easily create fallback logic. In this case we will use static inner class since we want the logic for the fallback to be part of the Client and not in a separate class.

Open: `modernize-apps/catalog/src/main/java/com/redhat/coolstore/client/InventoryClient.java`

And paste this into it at the `//TODO: Add Fallback factory here` marker:

~~~java
@Component
class InventoryClientFallbackFactory implements FallbackFactory<InventoryClient> {
  @Override
  public InventoryClient create(Throwable cause) {
        return itemId -> "[{'quantity':-1}]";
  }
}
~~~

After creating the fallback factory all we have to do is to tell Feign to use that fallback in case of an issue, by adding the fallbackFactory property to the `@FeignClient` annotation. Open the file to replace it at the `@FeignClient(name="inventory")` line:

~~~java
@FeignClient(name="inventory",fallbackFactory = InventoryClient.InventoryClientFallbackFactory.class)
~~~

**Slow running services**
Having fallbacks is good but that also requires that we can correctly detect when a dependent services isn't responding correctly. Besides from not responding a service can also respond slowly causing our services to also respond slow. This can lead to cascading issues that is hard to debug and pinpoint issues with. We should therefore also have sane defaults for our services. You can add defaults by adding it to the configuration.

Open ``modernize-apps/catalog/src/main/resources/application-default.properties``

And add this line to it at the `#TODO: Set timeout to for inventory to 500ms` marker:

~~~java
hystrix.command.inventory.execution.isolation.thread.timeoutInMilliseconds=500
~~~


In the next step we now test our service locally before we deploy it to OpenShift.

## Test Locally

As you have seen in previous steps, using the Spring Boot maven plugin (predefined in `pom.xml`), you can conveniently run the application locally and test the endpoint.

Execute the following command to run the new service locally:

~~~sh
mvn spring-boot:run
~~~~

> **INFO:** As an uber-jar, it could also be run with `java -jar target/catalog-1.0-SNAPSHOT-swarm.jar` but you don\'t need to do this now

Once the application is done initializing you should see:

~~~sh
INFO  [main] com.redhat.coolstore.RestApplication : Started RestApplication [...]
~~~

Running locally using `spring-boot:run` will use an in-memory database with default credentials. In a production application you will use an external source for credentials using an OpenShift _secret_ in later steps, but for now this will work for development and testing.

**3. Test the application**

To test the running application, navigate back to the CodeReady Workspaces and run the following in a new terminal:

`curl http://localhost:8081`

You should now see a html code deployed.

To see the raw JSON output using `curl`, you can open an new terminal window by and enter the following command to run the test:

`curl http://localhost:8081/services/product/329299 ; echo`

You would see a JSON response like this:

~~~json
{"itemId":"329299","name":"Red Fedora","desc":"Official Red Hat Fedora","price":34.99,"quantity":-1}
~~~

>**NOTE:** Since we do not have an inventory service running locally the value for the quantity is -1, which matches the fallback value that we have configured.

The REST API returned a JSON object representing the inventory count for this product. Congratulations!

**4. Stop the application**

Before moving on, be sure to stop the service by clicking on the first Terminal window and typing `CTRL-C`.

## Congratulations

You have now successfully created your the Catalog service using Spring Boot and implemented basic REST API on top of the product catalog database. You have also learned how to deal with service failures.

In next steps of this scenario we will deploy our application to OpenShift Container Platform and then start adding additional features to take care of various aspects of cloud native microservice development.

## Navigate to OpenShift dev Project

We have already deployed our coolstore monolith and inventory to OpenShift. In this step we will deploy our new Catalog microservice for our CoolStore application

In this step we'll deploy your new microservice to OpenShift, so let's navigate back to `ocpuser0XX-coolstore-dev`

From the CodeReady Workspaces Terminal window, navigate back to `ocpuser0XX-coolstore-dev` project by entering the following command:

`oc project ocpuser0XX-coolstore-dev`

## Deploy to OpenShift

Now that you've logged into OpenShift, let's deploy our new catalog microservice:

> **NOTE:** If you change the username and password you also need to update `modernize-apps/catalog/src/main/fabric8/credential-secret.yml` which contains
the credentials used when deploying to OpenShift.


**Update the Azure PostgreSQL database details**
Create the file : `modernize-apps/catalog/src/main/resources/application-openshift.properties`

Copy the following content to the file and replace {Azure PostgreSQL Hostname} and OCPUSER0XX with the values provided in the environment details page:

~~~java
spring.datasource.url=jdbc:postgresql://{Azure PostgreSQL HostName}:5432/ocpuser0XX?ssl=true&sslmode=require
spring.datasource.initialization-mode=always
inventory.ribbon.listOfServers=inventory:8080
~~~

Now, Open `modernize-apps/catalog/src/main/fabric8/credential-secret.yml` and update the `username` and `password` values with the `Azure PostgreSQL username and password` provided in the environment details page, in the format as seen below:

~~~
apiVersion: "v1"
kind: "Secret"
metadata:
  name: "catalog-database-secret"
stringData:
  #Update the value with Azure PostgreSQL username.
  user: "{Azure PostgreSQL Username}@{Azure PostgreSQL Hostname}"
  #Update the value with Azure PostgreSQL password.
  password: "{Azure PostgreSQL Password}"
~~~
>**NOTE:** The `application-openshift.properties` does not have all values of `application-default.properties`, that is because on the values that need to change has to be specified here. Spring will fall back to `application-default.properties` for the other values.

**Build and Deploy**

Build and deploy the project using the following command, which will use the maven plugin to deploy:

`mvn package fabric8:deploy -Popenshift`

The build and deploy may take a minute or two. Wait for it to complete. You should see a **BUILD SUCCESS** at the
end of the build output.

After the maven build finishes it will take less than a minute for the application to become available.
To verify that everything is started, run the following command and wait for it complete successfully:

`oc rollout status -w dc/catalog`

>**NOTE:** If you recall in the Quarkus lab Fabric8 detected the `health` _fraction_ and generated health check definitions for us, the same is true for Spring Boot if you have the `spring-boot-starter-actuator` dependency in our project.

**3. Access the application running on OpenShift**

This sample project includes a simple UI that allows you to access the Catalog API. This is the same
UI that you previously accessed outside of OpenShift which shows the CoolStore inventory. Click on the
route URL at

`http://catalog-ocpuser0XX-coolstore-dev.{{ROUTE_SUFFIX}}` to access the sample UI.

> /!\ Don't forget to change the user number in your route.

> You can also access the application through the link on the OpenShift Web Console Overview page.

<kbd>![](images/AROLatestImages/catalogpod.jpg)</kbd>

The UI will refresh the catalog table every 2 seconds, as before.

> **NOTE:** Since we previously have a inventory service running you should now see the actual quantity value and not the fallback value of -1

## Congratulations!

You have deployed the Catalog service as a microservice which in turn calls into the Inventory service to retrieve inventory data. However, our monolih UI is still using its own built-in services. Wouldn't it be nice if we could re-wire the monolith to use the new services, **without changing any code**? That's next!

## Strangling the monolith

So far we haven't started [strangling the monolith](https://www.martinfowler.com/bliki/StranglerApplication.html). To do this we are going to make use of routing capabilities in OpenShift. Each external request coming into OpenShift (unless using ingress, which we are not) will pass through a route. In our monolith the web page uses client side REST calls to load different parts of pages.

For the home page the product list is loaded via a REST call to *http://<monolith-hostname>/services/products*. At the moment calls to that URL will still hit product catalog in the monolith. By using a [path based route](https://docs.openshift.com/container-platform/3.7/architecture/networking/routes.html#path-based-routes) in OpenShift we can route these calls to our newly created catalog services instead and end up with something like:

<kbd>![](images/AROLatestImages/ImageCatalog.JPG)</kbd>

Flow the steps below to create a path based route.

**1. Obtain hostname of monolith UI from our Dev environment**

`oc get route/www -n ocpuser0XX-coolstore-dev`

> /!\ Change the project name according to your user number

The output of this command shows us the hostname:

~~~sh
NAME      HOST/PORT                                 PATH      SERVICES    PORT      TERMINATION   WILDCARD
www       www-ocpuser0XX-coolstore-dev.{{ROUTE_SUFFIX}}             coolstore   <all>                   None
~~~

My hostname is `www-ocpuser0XX-coolstore-dev.{{ROUTE_SUFFIX}}` but **yours will be different**.

**2. Open the OpenShift Console for "Coolstore Monolith Dev" and navigate to Networking -> Routes

<kbd>![](images/AROLatestImages/catalogroute.jpg)</kbd>

**3. Click on Create Route, and set**

* **Name**: `catalog-redirect`
* **Hostname**: _the hostname from above_
* **Path**: `/services/products`
* **Service**: `catalog`

<kbd>![](images/AROLatestImages/catalogredirect1.jpg)</kbd>

Leave other values set to their defaults, and click **Create**

**4. Test the route**

Test the route by running `curl http://www-ocpuser0XX-coolstore-dev.{{ROUTE_SUFFIX}}/services/products`

You should get a complete set of products, along with their inventory.

**5. Test the UI**

Open the monolith UI at

`http://www-ocpuser0XX-coolstore-dev.{{ROUTE_SUFFIX}}` and observe that the new catalog is being used along with the monolith:

<kbd>![](images/mono-to-micro-part-2/coolstore-web.png)</kbd>

The screen will look the same, but notice that the earlier product *Atari 2600 Joystick* is now gone, as it has been removed in our new catalog microservice.

## Congratulations!

You have now successfully begun to _strangle_ the monolith. Part of the monolith's functionality (Inventory and Catalog) are now implemented as microservices, without touching the monolith. But there's a few more things left to do, which we'll do in the next steps.


## Summary

In this scenario you learned a bit more about what Spring Boot and how it can be used together with OpenShift and OpenShift Kubernetes.

You created a new product catalog microservice representing functionality previously implemented in the monolithic CoolStore application. This new service also communicates with the inventory service to retrieve the inventory status for each product.
