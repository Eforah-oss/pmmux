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

### How do I use it?

Like the example above, but I'll elaborate later.

### Where does it work?

UNIX-like systems and Windows. In other words: every modern operating
system such as macOS, Windows, Linux etc. It works fine in the WSL,
transparently calling choco.exe if it is available.
