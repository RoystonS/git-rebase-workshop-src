# Git Interactive Rebase Workshop

## Getting started

1. Clone the repo
1. Take a look through the commits; it's meant to simulate a developer
   makings a series of little commits whilst working on a larger task,
   and then wanting to tidy up.

## Tasks

### Familiarisation

Take a look through the repo and its history.

It's a simple .NET CLI tool, and the commits show a developer playing
around with some implementation details over the course of quite
a few commits.

We want to tidy all that up before we create a PR, and we don't necessarily
want to just squash everything down to a single commit.

### Remove stray files

Oops, we checked in a bunch of `bin/` and `obj/` files by mistake
very early on in the commits (at 09:05).

We don't want to remove the entire commit as it does contain the initial
`Program.cs` code.

#### Problem

Using an interactive rebase, edit that commit and remove the obj/ entries.

#### Solution

1. Begin an interactive rebase back to the 09:00 commit
1. Edit the 09:05 commit
1. Unstage and discard the files from `bin/` and `obj/`
1. Continue the rebase
1. You'll see a conflict with a later commit, as that commit made changes to the
   bin/ and obj/ files that were checked in in the earlier commit.
   Select the files from your temporary rebase branch rather than your PR branch.
