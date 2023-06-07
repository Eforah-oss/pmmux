pmmux - package manager multiplexer
===================================

This small and very portable utility solves a part of bootstrapping
a system: installing other software using the relevant package
manager. Which package manager that is, is determined at runtime. That
is the power of `pmmux`. Let's see why this is useful with an example:

    pmmux -1 choco+pip apt+python3-pip brew+python pacman+python-pip

As you can probably guess, this installs pip. The added value is in
the fact that this command works on a few Linux distributions, macOS,
and even Windows! Read on if you want to learn more.

### Is `pmmux` for me?

`pmmux` is for people who deal with different distributions and operating
systems, and want some consistency/ease in installing a set of packages
from different sources. This might include team leads who want to provide
a script to install the system dependencies of a software project to their
colleagues without resorting to heavyweight technologies like Docker.

### How does it work?

`pmmux` is given a list of package managers and their arguments like
the example above. This first package manager actually present on the
system it is run on is used to install the package name given in that
argument.

### Where does it work?

UNIX-like systems and Windows. In other words: every modern operating
system such as macOS, Windows, Linux etc. It works fine in the WSL,
transparently calling choco.exe if it is available.

## Installation
### Windows (PowerShell)
    irm 'https://raw.githubusercontent.com/Eforah-oss/pmmux/master/pmmux.ps1' `
        | % {$_ - replace "pmmux @args$", "pmmux -1 pmmux+pmmux"} | iex
### macOS/Linux etc.
    git clone https://github.com/Eforah-oss/pmmux
    cd pmmux
    sudo make install
