# ecocor-api

eXist extension providing REST API for EcoCor

## Getting started

```sh
git clone https://github.com/dh-network/ecocor-api.git
cd ecocor-api
docker compose up
```

We provide a [compose.yml](compose.yml) that allows to run an eXist database
with `ecocor-api` locally. With
[Docker installed](https://docs.docker.com/get-docker/) simply run:

```sh
docker compose up
```

This builds the necessary images and starts the respective docker containers.
The **eXist database** will become available under http://localhost:8090/.
To check that the EcoCor API is up run

```sh
curl http://localhost:8090/exist/restxq/ecocor/info
```

## Building the eXist extension

For packaging the ecocor-api code into an eXist extension archive (XAR)
[Apache Ant](https://ant.apache.org) is required. (On macOS it can be installed
with homebrew: `brew install ant`.)

Simply running

```sh
ant
```

creates an  ecocor-x.x.x.xar archive in the `build` directory. This can be
installed into an existing eXist DB instance.

## Visual Studio Code integration

The [existdb-vscode](https://marketplace.visualstudio.com/items?itemName=eXist-db.existdb-vscode)
extension allows for developing XQuery code targeted at eXistdb and sync it with
a running database instance. We provide a configuration template that integrates
VS Code with the eXist instance from `docker compose`. Run

```sh
ant existdb.json
# or
cp .existdb.json.tmpl .existdb.json
# and edit the docker.port placeholder
```

to create a configuration file. For usage details see the
[extension's documentation](https://marketplace.visualstudio.com/items?itemName=eXist-db.existdb-vscode).
