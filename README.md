# Cloud Foundry Java Liferay Buildpack

This buildpack if a fork of the Java buildpack and is designed to summarizes the work done when developing a custom buildpack to be able to support Liferay on CloudFoundry. 

## Description
To use this buildpack specify the URI of the repository when pushing an application to Cloud Foundry:

```bash
$ cf push <APP-NAME> -p <ARTIFACT> -b https://github.com/cloudfoundry/java-buildpack.git
```

## Usage
The following are _very_ simple examples for deploying the artifact types that we support.

* [Embedded web server](docs/example-embedded-web-server.md)
* [Grails](docs/example-grails.md)
* [Groovy](docs/example-groovy.md)
* [Java Main](docs/example-java_main.md)
* [Play Framework](docs/example-play_framework.md)
* [Servlet](docs/example-servlet.md)
* [Spring Boot CLI](docs/example-spring_boot_cli.md)

## Database configuration


## Session replication

## Troubleshooting


```bash
$ cf set-env my-application JBP_CONFIG_OPEN_JDK_JRE '{jre: { version: 1.7.0_+ }}'
```

If the key or value contains a special character such as `:` it should be escaped with double quotes. For example, to change the default repository path for the buildpack.

```bash
$ cf set-env my-application JBP_CONFIG_REPOSITORY '{default_repository_root: "http://repo.example.io"}'
```

