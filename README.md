# saurons-workbench

Rapidly prototype and launch a core lightning stack using Sauron and Workbench.

## How to use

*Make sure that docker is installed, and you are part of docker group.*

```
## Download the repository onto your machine.
git clone *this repository url*
cd saurons-workbench

## Launch a node on testnet.
./workbench.sh start alice --chain testnet

## Launch a node on mainnet.
./workbench.sh start bob

## To see a list of commands.
./workbench --help
```

This project uses a stripped version of regtest-workbench. For a deeper introduction, check out https://github.com/cmdruid/regtest-workbench

## Contribution

All contributions are welcome! If you have any questions, feel free to send me a message or submit an issue.

