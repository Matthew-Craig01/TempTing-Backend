[TempTing][https://github.com/Matthew-Craig01/TempTing]
# Backend
The backend is built with [Gleam](https://gleam.run/) and runs on Erlang's BEAM VM. In order to run the backend, you must first install Gleam and Erlang: [instructions](https://gleam.run/getting-started/installing/)

## Build the backend

```sh
gleam build
```

## Create DB
⚠️ This will delete the current database.
```sh
gleam run create
```

## Run Server
⚠️ This will delete the current database.
```sh
gleam run
```
