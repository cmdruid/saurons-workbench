# Sauron's Workbench

A docker workbench environment, pre-configured for running Core Lightning with Sauron plugin (using Blockstream API).

## Overview

Here is an overview of the project filesystem:

```sh
## Project Directory

/build       # Contains a build script, plus dockerfiles for
             # downloading, compiling and building binaries.
             # Compressed binaries are saved in 'out' path.

/config      # Mounted as read-only at /config.
             # Useful for collecting our config files in 
             # one place, so we can tweak them between builds.

/home        # Mounted as read-write at /root/home.
             # Scripts placed in 'bin' are added to your PATH 
             # environment. The .bashrc script is loaded at login.

/image       # Copied to root filesystem '/' at build time.
             # Create your desired filesystem in here, using the 
             # proper paths. (for ex. binaries in /image/usr/bin/')

.env.sample  # Example of .env file. Used for setting variables that
             # are passed into the build and runtime environments.

compose.yml  # Container configuration file. Launch your container in 
             # detached mode by using: 'docker compose up --build -d'

Dockerfile   # Main build file for the docker container. Feel free to 
             # configure this file to your liking!

README.md    # You are here!
```

## How to Setup

Before launcing your project in workbench, you may need to setup the environment.

### /build

The `build` directory is where you will find the main `build.sh` script, plus any dockerfiles that are used to download and build the binary packages for your system. Packaged binaries are stored in the `build/out` directory. You can then unpackage (`tar -xvf package.tar.gz` in linux) and move these files to your `image` directory. 

> **NOTE:** If you are running on Windows, you may need to use WSL in order to run the build.sh script, or run the dockerfiles using docker build.

### /image

The `image` directory defines your container's default filesystem, and is where your main binaries will be stored. The included `clightning` binaries should work, however if you need to replace them, you can use the `build.sh` script and `clightning.dockerfile` located in `build/dockerfiles` to build a custom binary package for your system. Make sure to unpack and store your binaries in `image/usr/bin` or `image/usr/local/bin` so they can be called from the command-line. For more information on how to build Core Lightning from source, see their [github page](https://github.com/ElementsProject/lightning).

### /config

The `config` folder contains configuration files for services running within the container. The default configuration should be fine, however you may wish to adjust some settings (port numbers for example).

### /home

The `home` folder contains the main `entrypoint` and `start` scripts used to start the container. Feel free to tweak these scripts for your own needs!

### Configuring your Container

The `env.sample` file contains additional configurations that you may wish to change for your project. Copy and rename this file to `.env`, then cutomize it to your needs. The file will take effect automatically on startup.

The `compose.yml` and `Dockerfile` are used to configure and setup the container. The default configurations should be fine, however you may wish to change some things. Please see the resource links below for more information on how to customize these files.

**Tips**  

- The `Dockerfile` specifies what packages are installed by default. Modify the `apt install` line to add more packages to your container.
- The `home` folder is reloaded upon login, so you can make changes to your environment frequenlty!
- Use the `home/bin` folder to store your own custom scripts (and call them directly).
- Use the `.init` and `.profile` scripts to customize your own shell environment.
- Feel free to `--build` frequently as you make changes to the filesystem.

## How to Use
```sh
## Build the image and start in a container.
docker compose up --build

## Start the container in detached mode.
docker compose up -d

## You can also do all of this in one line.
docker compose up --build -d

## Log into a currently running container.
docker exec -it <container name> bash

## If you have any issues with starting your container,
## log into the container's shell, then start the script.
docker compose run -it --entrypoint bash <container name>
<~/home> entrypoint
```

### Plugins

Core Lightning has a plugins system that allows you to hook into the main process and modify / extend it to your liking. There are many different events that you can hook into. For more information, see their [guide here](https://github.com/ElementsProject/lightning/blob/master/doc/PLUGINS.md).

Plugins are stored in the `image/plugins` directory, and can be configured to load on startup in the `config/lightningd.conf` file. For a list of existing plugins, check out [this repository](https://github.com/lightningd/plugins).

In order to create a custom plugin, your app will need to generate a manifest.json file that Core Lightning uses to launch and control your app. There's a few libraries that will handle this part for you. This project includes [pycln-client](https://github.com/ElementsProject/lightning/tree/master/contrib/pyln-client) for python projects, and [clightningjs](https://github.com/darosior/clightningjs) for nodejs projects. There is also a go library available [here](https://pkg.go.dev/github.com/fiatjaf/lightningd-gjson-rpc/plugin#section-readme).

### Spark API / Webhooks

The [spark](https://github.com/fiatjaf/sparko) and [webhook](https://github.com/fiatjaf/lightningd-webhook) plugins offer easy API access to your node. The spark plugin also offers a simple web-based wallet for your lightning node. Certificates, keys and login information is generated on startup and stored in the `data` folder. Additional configuration is available in the `config/lightningd.conf` file. For an example web client, see [sparko-client](https://www.npmjs.com/package/sparko-client).

### Tor Integration

Setting `TOR_ENABLED=1` in your `.env` file will enable Tor integration. This will configure your lightning node to connect with peers over tor, as well as configure your `spark-qr` command to use an onion address.

### Ngrok Integration

Setting `NGROK_ENABLED=1` in your `.env` file will enable Ngrok integration. This will configure your `spark-qr` command to connect using an encrypted Ngrok tunnel. You will have to sign up [here](https://ngrok.com) in order to receive an `NGROK_TOKEN` and use their service.

### Zeus Wallet

[Zeus Wallet](https://github.com/ZeusLN/zeus) is a bitcoin / lightning wallet that connect directly to your lightning node. Zeus is compatible with using Sparko QR codes to connect to your node, which you can generate via running the `spark-qr` command within your container's shell.

## Resources

For more information and resources, please see the links below.

**Core Lightning (CLN)**  
https://github.com/ElementsProject/lightning

**Bolt Payment Specification**  
https://github.com/lightning/bolts

**Docker Compose Reference**  
https://docs.docker.com/compose/compose-file

**Docker Builder Reference**  
https://docs.docker.com/engine/reference/builder

**Docker Exec Reference**  
https://docs.docker.com/engine/reference/commandline/exec
