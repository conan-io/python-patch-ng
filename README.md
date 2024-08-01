[![CI Status](https://github.com/conan-io/python-patch-ng/actions/workflows/workflow.yml/badge.svg)](https://github.com/conan-io/python-patch-ng/actions/workflows/workflow.yml)
[![PyPI](https://img.shields.io/pypi/v/patch-ng)](https://pypi.python.org/pypi/patch-ng)

## Patch NG (New Generation)

#### Library to parse and apply unified diffs.

#### Why did we fork this project?

This project is a fork from the original [python-patch](https://github.com/techtonik/python-patch) project.

As any other project, bugs are common during the development process, the combination of issues + pull requests are
able to keep the constant improvement of a project. However, both community and author need to be aligned. When users,
developers, the community, needs a fix which are important for their projects, but there is no answer from the author,
or the time for response is not enough, then the most plausible way is forking and continuing a parallel development.

That's way we forked the original and accepted most of PRs waiting for review since jun/2019 (5 months from now).

### Features

 * Python 2 and 3 compatible
 * Automatic correction of
   * Linefeeds according to patched file
   * Diffs broken by stripping trailing whitespace
   * a/ and b/ prefixes
 * Single file, which is a command line tool and a library
 * No dependencies outside Python stdlib
 * Patch format detection (SVN, HG, GIT)
 * Nice diffstat histogram
 * Linux / Windows / OS X
 * Test coverage

Things that don't work out of the box:

 * File renaming, creation and removal
 * Directory tree operations
 * Version control specific properties
 * Non-unified diff formats


### Usage

Download **patch_ng.py** and run it with Python. It is a self-contained
module without external dependencies.

    patch_ng.py diff.patch

You can also run the .zip file.

    python patch-ng-1.17.zip diff.patch

### Installation

**patch_ng.py** is self sufficient. You can copy it into your repository
and use it from here. This setup will always be repeatable. But if
you need to add `patch` module as a dependency, make sure to use strict
specifiers to avoid hitting an API break when version 2 is released:

    pip install "patch-ng"


### Other stuff

* [CHANGES](doc/CHANGES.md)
* [LICENSE: MIT](LICENSE)
* [CREDITS](doc/CREDITS)
