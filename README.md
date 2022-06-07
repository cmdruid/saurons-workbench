# bitcoin-daemon

Launch a simple, light-weight (and torified!) bitcoin daemon using Docker.

## How to use

*Make sure that docker is installed, and you are part of docker group.*

```
git clone *this repository url*
cd bitcoin-daemon
./start.sh
```
### /build

The main dockerfile will copy all binaries located in the `build/out` path. If required binaries are missing, they will be compiled from source and build using dockerfiles included in the `build/files` path.

### /config

Each time the docker image is rebuilt, these config files will be copied over. If you want to modify the existing configuration, simply run `./start.sh` with the argument `--build` (or `--rebuild`) in order to update your container with the latest changes.

### /run

These scripts are copied into the `/root/run` folder when the docker image is built. The main entrypoint script will then execute the scripts located in `/root/run/startup` in lexical order. Feel free to modify the existing scripts, or add your own!

### /snapshot

This folder is for storing pruned snapshots of the bitcoin blockchain. If your container does not have an existing blockchain saved, then this folder will be checked for a saved snapshot that it can use.

You can find snapshots of the blockchain located here:
https://prunednode.today

If you plan to use a pruned snapshot of the blockchain, make sure to uncomment the `prune` option in `config/bitcoin.conf`.

If you have an existing blockchain, you must remove it first in order for a snapshot to be used. You can perform this by deleting the existing `bitcoin-daemon-data` volume, or log into the container using `docker exec -it bitcoin-data` and remove all files located in the `/data/bitcoin` directory.

## Contribution

All contributions are welcome! If you have any questions, feel free to send me a message or submit an issue.

## Resources

Bitcoin Core Config Generator:
https://jlopp.github.io/bitcoin-core-config-generator
