SML# Package Builder
====================

This repository contains scripts building SML# release packages.
When a new version of the SML# compiler is released, these scripts
are used to build deb, rpm, and homebrew packages and update [repos]
and [homebrew-smlsharp].

Prerequisites
-------------

* Docker is needed.
* macOS and Homebrew is needed to build homebrew formulae and bottles.

How to use
----------

### Preparation

1. Set up Docker images by running `docker/setup.sh`.

2. In the SML# source tree, run `make dist`.
   You will find the source package named `smlsharp-X.Y.Z.tar.gz` and
   history file `smlsharp-X.Y.Z.history` (substitute X.Y.Z with the actual
   version number).
   Copy them to the `smlsharp-package` directory.

3. In the `smlsharp-package` directory, clone the [repos] and
   [homebrew-smlsharp] repository from GitHub.

4. Put `signing-key_<USER>.asc` and `ppa-key_<USER>.asc` in the
   `smlsharp-package` directory (substitute `<USER>` with your login name).
   These must be GPG-encrypted files, each of which contains a pair of
   a secret GPG key and its password.

### Package Build

Because operating systems evolve very rapidly, this repository needs to
be maintained frequently.  It had better to review the scripts in this
repository before you intend to use them.  The following steps indicate
typical usage of the scripts, but you should assume that the scripts
does not work smoothly as follows:

1. Run `make`.  Then, you will find `BUILD/all.tar` file.

2. Run `make install` to update `repos`.  It creates a new branch named
   `new` in the `repos` repository and commit all the changes in that
   branch.

3. Run `make install-brew` to update `homebrew-smlsharp`.  Similarly to
   step 5, `new` branch is created in the `homebrew-smlsharp` repository.

4. For each repository, merge the `new` branch into the master branch
   (`main` or `master`) and push the changes to GitHub.

Contributing
------------

Submit issues and PRs on GitHub.

[repos]: https://github.com/smlsharp/repos
[homebrew-smlsharp]: https://github.com/smlsharp/homebrew-smlsharp
