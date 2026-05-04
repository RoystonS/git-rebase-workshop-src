# Git Interactive Rebase Workshop

This is a repo which simulates a user creating a PR, committing
early and often during the PR process, and then needing to
tidy up the PR before final submission, to keep a tidy repo and
make the life of a PR reviewer easier.

It demonstrates how to do interactive rebases, reordering, merging and dropping
commits and editing commits to remove unnecessary content.

## Getting started

1. Clone the repo from https://github.com/RoystonS/git-rebase-workshop
1. Switch to the pr/new-work branch

This is the PR branch that you're intending on turning into a tidier PR.

## Notes

If at any point you discover that you've created a merge commit, stop, and
go back to a previous step. This is easily done if you create a git tag just
after each successful step: you can then hard-reset the PR branch to that tag.

## Tasks

### Familiarisation

Take a look through the repo and its history.

It's a simple .NET CLI tool, and the commits show a developer playing
around with some implementation details over the course of quite
a few commits.

There are a few commits on `main`, and our `pr/new-work` branch was created
just before the last `origin/main` commit. So we were one commit behind
when we created our PR branch.

We want to tidy up the commits in our branch, and ensure we're up to date
before we create a PR for our branch. We don't necessarily
want to just squash everything down to a single commit.

Let's work through some tasks:

### Remove stray files

Oops, we checked in a bunch of `bin/` and `obj/` files by mistake
very early on in the commits (at <COMMIT_TIME:first_bad_bin_obj>).

We could create another commit which removes those files, but if we left
both the original add commit and the remove commit in our PR, we would
end up pushing those files into our repo, which would unnecessarily bloat
our repo.

We should ensure they're not present in our branch at all.

We can't remove the problematic commit entirely as it does contain the initial
`Program.cs` code.

#### Problem

Using an interactive rebase, edit that commit and remove the `bin/` and `obj/` entries.

#### Solution

1. Begin an interactive rebase, back to the <COMMIT_TIME:prefork> commit (where the PR forked)
1. Edit the <COMMIT_SHA:first_bad_bin_obj> commit (at <COMMIT_TIME:first_bad_bin_obj>)
1. Unstage and discard the files from `bin/` and `obj/`
1. Continue the rebase
1. You'll see a conflict with a later commit (the <COMMIT_TIME:second_bad_bin_obj> commit),
   as that commit made changes to the bin/ and obj/ files that were checked in in the earlier commit.
   Select the files from your temporary rebase branch rather than your PR branch.
1. Continue and complete the rebase

### Move the `.gitignore` creation to the project creation commit

Whilst working on the repo, we did notice this problem, and we added a `.gitignore`
file, in the <COMMIT_TIME:addgitignore> commit.

That's a little late in our set of PR commits.

#### Problem

Having a `.gitignore` file in our PR is good.
Having it so late in the commits in our PR is bad.

Using an interactive rebase, move the commit down and make it part of the
<COMMIT_TIME:postfork> commit, where the project was created.

#### Solution

We need to edit the <COMMIT_TIME:postfork> commit.

So:

1. Begin an interactive rebase, back to the <COMMIT_TIME:prefork> commit (i.e.
   immediately before the <COMMIT_TIME:postfork> commit)
1. Reorder the commits so that the `.gitignore` commit (<COMMIT_TIME:addgitignore>)
   is immediately after the project-creation (<COMMIT_TIME:postfork>) commit
1. Change the `.gitignore` commit to be 'Fixup' mode so that it will be merged
   into the <COMMIT_TIME:prefork> commit
1. Run the rebase
1. Look at the <COMMIT_TIME:postfork> commit and see that the `.gitignore` change is now in there too

### Make vulnerability fix available to others

Whilst on that branch we noticed, and fixed, a vulnerable package (after
an appropriate investigation). Before we do anything else, we want to
make that fix available to other people.

#### Problem

Pull that change out into a new PR branch so it can be submitted immediately
as a separate PR, without waiting on the rest of the work from this branch.

#### Solution

This one doesn't require any rebasing. Just a new branch and a cherry-pick.

1. Create a new branch, `pr/fix-vulnerability`, immediately off the `origin/main` branch, and check it out.
1. Cherry-pick the vulnerability fix (at <COMMIT_TIME:fixvulnerability>) commit
   onto that branch, immediately committing it.

If we were really doing this in a team environment, we'd be pushing that PR branch
to share with others.

### Reduce duplication, and update

We now have that same vulnerability commit twice, once, late on, in our PR,
and once in another PR destined for `main`.

Also, as we said earlier, our PR branch is a little out of date with respect to the `main` branch.

It's unlikely that there will need to be changes to that vulnerability PR,
so let's assume it will get merged, and base our work off it.

#### Problem

Rebase our PR branch so it picks up the latest changes from main and the vulnerability branch.

Did that clean up our branch structures or make it worse?

#### Solution

1. Check out our PR branch again.
1. Rebase it (not an interactive rebase) onto the vulnerability PR branch.
1. Inspect the branch structure carefully. Notice:
   1. We're up to date. The `pr/new-work` branch is entirely up to date with `origin/main` plus the vulnerability-fix PR.
   1. We have a nice linear history. The `pr/new-work` branch has a nice
      line of commits, and is based on the vulnerability-fix branch, which
      itself is based on `origin/main`.

      There are no merge commits in there, so it's easy to read.
      The timestamps do jump about a bit though.

   1. The vulnerability fix commit now only appears once.
      When performing the rebase, Git effectively replayed all of our
      PR branch commits, but it noticed that there was already an equivalent
      (based on content, not name or id) commit in the new branch, so it was
      removed.

### Remove debug

One of the dangers of simply squashing all the commits down is that it's very
easy to leave intentionally-temporary changes (e.g. debug logs) in there.

Although we have a mess of commits in this PR, we were careful to add debug logs
in their own separate commits (at <COMMIT_TIME:debug1> and <COMMIT_TIME:debug2>).

So we can now just remove those debug log entries without having to hunt through
the files looking for them, and without depending on our PR reviewers to spot them.

#### Problem

Remove the debug content.

#### Solution

Earlier we edited a commit to remove the `obj/` and `bin/` files from that commit.
This one's easier as we can just drop the commits entirely.

1. Begin an interactive rebase, back to the commit immediately before
   the first debug commit (at <COMMIT_TIME:debug1>).
1. Mark the two debug commits (at <COMMIT_TIME:debug1> and <COMMIT_TIME:debug2>)
   for 'Drop' actions.
1. Run the rebase.

Ta-da. The temporary debug is gone without our having to hunt it down individually,
aided by our separating it out into its own commits.
