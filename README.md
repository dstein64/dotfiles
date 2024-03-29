[![build][badge_thumbnail]][badge_link]

dotfiles
========

My personal dotfiles.

Installation
------------

#### Install

```sh
$ git clone https://github.com/dstein64/dotfiles ~/.dotfiles
```

#### Update

```sh
$ cd ~/.dotfiles
$ git pull origin master
```

Usage
-----

#### List available packages

```sh
$ ls -1 ~/.dotfiles/packages
```

#### Install specific packages

```sh
$ ~/.dotfiles/install.sh package1 [package2 ...]
```

#### Install all packages

```sh
$ ~/.dotfiles/install.sh
```

Cleanup
-------

Using `install.sh` to *update* packages does not remove files and directories that
have been deleted or moved. Cleanup has to be done manually.

License
-------

The source code has an [MIT License](https://en.wikipedia.org/wiki/MIT_License).

See [LICENSE](https://github.com/dstein64/dotfiles/blob/master/LICENSE).

[badge_link]: https://github.com/dstein64/dotfiles/actions/workflows/build.yml
[badge_thumbnail]: https://github.com/dstein64/dotfiles/actions/workflows/build.yml/badge.svg
