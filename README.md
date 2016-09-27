# Cloud Foundry Java Liferay Buildpack (IN PROGRESS)

This buildpack is a fork of the Java buildpack and is designed to support Liferay on CloudFoundry. To do so, the Java builpack has been extended using a Versioned Dependency Component [Version Dependency Component][] this is because we are using the buildpack repository support to download the liferay war file dependency. It ensures that the war has a @version and @uri that were resolved from the repository specified in the configuration.

In short, the goal was to be able to deploy Liferay portal and its applications (ex: portlets, etc.) on CloudFoundry.


## Usage

TODO

The applications (ex. Portlets, Themes, etc.) that need to be deployed should be packaged inside a zip file. Let say I’m deploying several portlets which are contained in 2 war files helloworld1.war and helloworld2.war. These 2 files should be compressed in one file (let call it portlets.zip); the name of this later does not matter since only the exploded version will be presented to the buildpack. In this example if I list the content of the zip file, I should have something like this.

```
├── portlets.zip
│   ├── myPortlet.war
│   ├── myTheme.war
│   └── myOtherPortlet.war
```

## Database configuration

By default the installation will make use of an in-memory database (HSQL) provided by Liferay. However in an enterprise scenario, a MySql database is used and the good new is that the liferay-buildpack can automatically bind the application to an existing MySQL service. For that to happen, the service has to be created and named: lf-mysqldb in the space where the application has to be deployed. Once this is done, the application has to be bound to that service during the push (see the example section for more details). MySQL is the most used database in the Liferay world that why I have decided to make it the main focus. However it should not be a big deal in the future to support other type of Database. 

One issue I faced during testing is regarding the connexion pool size. On PWS, the maximum number of connection you can get is 40. And the default maximum connection pool size is 100. So if you don’t have your own PCF installation where you can define your MySQL capacity, I have incorporated in the buildpack a way of changing that default value.  This can be helpful when testing on PWS.  

This value can be change through environment variable (see the example section) using the following key name: LIFERAY_MAX_POOL_SIZE. When testing on PWS, based on your ClearDB MySQL plan you can set that value to 10, 15, 30 or 40. 

NOTE: I did my tests using PCF Dev [PCF Dev][]  without any issue 

TODO


## Troubleshooting

The best way to troubleshoot is to activate the Debug mode and go through the log files. You can also verify each of the following points, which I have encountered during the development of the buildpack.  If you are still having some issues, please do not hesitate to create an issue.

* Maximum Pool size set too low: If you are using a database, verify your database can accept the specify number of connections.  Refer to point 2.c and 2.e on how to indicate to Liferay the maximum pool size to use. If your maximum pool size is set too low, the application might have trouble to start up. Make sure this value is not set below 20.

* Not enough memory:  The default portal requires at least 1.5G of memory, so if you are trying to deploy lot of portlets make sure your application is configure to use enough memory. If your space is name “development”, use the following command to check your application instance memory limit:

`` cf space development ``


* You might also be running out of disk space, so check your PCF installation.

[Version Dependency Component]: https://github.com/cloudfoundry/java-buildpack/blob/master/docs/extending-versioned_dependency_component.md
[PCF Dev]: https://network.pivotal.io/products/pcfdev
