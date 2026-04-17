---
name: nix-evaluator
description: This skill is used to evaluate the current state of this repository's flake, and any actionable errors contained within. This should be run until each step reports 0 errors before concluding any task to ensure the repository functions correctly and matches convention. It should always be used before reporting to the user that any nix code modification has been completed, as a "final checker" so to speak
---

# Nix Evaluator

## Overview

This skill guides the agent through final required modification or alteration
checks, it's fundamental purpose is to maintain the actual functionality of the
project at all times by providing an iterable action to diagnose the most
pressing evaluation error at any given time.

Successful completion of this skill means the project is ready for
commit & push to the git remote, any failure should be deemed catastrophic as
it means a live system will ingest code that will possibly permanently break
either the software or hardware configuration of said system.

## Workflow

### Step 1: Check for any changes in git

Check to ensure all modifications in the current worktree are staged as nix
will refuse to evaluate any file git can't see

```bash
git status
```

- **If there are unstaged changes**: Stage them with step 2
- **If all changes are staged**: Proceed to step 3

### Step 2: Stage all unstaged changes

If there are changes be sure to stage them to ensure proper flake evaluation

```bash
git add .
```

### Step 3: Check the current state of the flake

This is the actual error checking command, be sure to run this in a loop until
no errors are reported.

```bash
nix fmt && nix flake check --all-systems --show-trace
```

- **Does this report any errors**: Prompt the user if they would like this
  error fixed as a part of the loop or not if
  and only if the error is outside of the
  scope of the initial discussion. If the
  user declines, exit this skill loop,
  and return control to the user.
- **Does this not report any errors at all**: Exit this skill loop,
  and return control to the user.
