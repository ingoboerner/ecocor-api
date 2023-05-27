# ecocor-api

eXist extension providing REST API for EcoCor

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
