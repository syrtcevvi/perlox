# Perlox - Lox language implementation written in the Perl language

[![Check Perl files](https://github.com/syrtcevvi/perlox/actions/workflows/ci.yml/badge.svg)](https://github.com/syrtcevvi/perlox/actions/workflows/ci.yml)

This is a tree-walking interpreter implementation for the **Lox** language written in Perl.

> This implementation doesn't strictly follow the path which the book "Crafting Interpreters" takes, but is greatly inspired by that.

Currently it's highly **WIP**, but some parts look like a working ones :)

## Setup

### Get the copy of this repository

```bash
git clone https://github.com/syrtcevvi/perlox.git
cd perlox
```

### Install the prerequisites
#### Ubuntu 24.04

**deploy/packages.sh** just contains some *.deb* packages with necessary Perl packages.

```bash
deploy/packages.sh
```

Currently I don't use packages that can not be found in the apt registry via `apt-cache search <Some::Package::Name::Here>`.

### Run checks
#### Check syntax of all source files

```bash
deploy/run_checks.sh
```

#### Run tests

> TODO

## Run the REPL!

To start the interactive REPL type the following:

```bash
bin/perlox
```

To enable some debug output from the **scanner** and **parser** stages pass the `--verbose` flag:
```bash
bin/perlox --verbose
```

Currently it does no evaluation, so it's can be used just to see some debug output given some input.

