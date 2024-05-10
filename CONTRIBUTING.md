Original file: [https://github.com/pulp-platform/iDMA/blob/master/CONTRIBUTING.md](https://github.com/pulp-platform/iDMA/blob/master/CONTRIBUTING.md)

# Contribution Guide

We are happy to accept pull requests and issues from any contributors. Please
note that we try to maintain a consistent quality standard. For a quick overview
please find some of the most important points below.

## Quick Overview

* Keep a clean commit history. This means no merge commits, and no long series
  of "fixup" patches (rebase or squash as appropriate). Structure work as a
  series of logically ordered, atomic patches. `git rebase -i` is your friend.
* Changes should only be made via pull request, with review. A pull request will
  be committed by a "committer" (an account listed in `CODEOWNERS`) once it has
  had an explicit positive review.
* When changes are restricted to a specific area, you are recommended to add a
  tag to the beginning of the first line of the commit message in square
  brackets e.g., "uart: Fix bug #157".
* Areas which are not clear by their name alone (e.g., "vendor") should be
  separated by a slash. For example "hw/vendor: Add patch directory".
* Create pull requests from a fork rather than making new branches in
  `github.com/TheMightyDuckOfDoom/liberty74`.
* Do not force push.
* Do not attempt to commit code with a non-Solderpad license without discussing
  first.
* If a relevant bug or tracking issue exists, reference it in the pull request
  and commits.

## Git Considerations

* Separate subject from body with a blank line
* Limit the subject line to 100 characters
* Capitalize the subject line
* Do not end the subject line with a period
* Use the imperative mood in the subject line
* Use the body to explain what and why vs. how

For further information please see the excellent
[guide](https://chris.beams.io/posts/git-commit/) by Chris Beams.

## Code Style

Consistent code style is important. We try to follow existing style conventions
as much as possible:

* For RTL we use [lowRISC's SystemVerilog style
  guidelines](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)
  and lint using `verible-verilog-lint`.
* For Python code we follow the official [`pep8` style
  guide](https://www.python.org/dev/peps/pep-0008/) and lint using `pylint`.
* For `yaml` files (such as the `Bender.yml`) we lint using `yamllint`.
* For `md` files (such as the `Readme.md`) we lint using `mdl`.
* For `json` files (such as the `config/footprints.json`) we lint using `jsonlint`.
* For `tcl` files (such as the `openroad/chip.tcl`) we lint using `tclint`.

Please make sure that any code you submit is adhering to the correct standard.
You can check if all files pass the linters using `make lint`.
