# Security and publishing

This repository can be shared publicly when credentials and machine-specific configuration remain local. A clean current tree alone does not establish that earlier commits are safe to publish.

## Before making the repository public

- Run a dedicated secret scanner such as [Betterleaks](https://github.com/betterleaks/betterleaks) against the full Git history, including every branch and tag intended for publication. Investigate each finding; pattern scans can miss secrets.
- Review tracked files and historical content for private keys, tokens, passwords, credential-bearing URLs, internal hostnames, server addresses, and employer-specific configuration.
- Review commit author and committer names and email addresses. Use a GitHub noreply address for future commits if you prefer to keep your email private; changing Git configuration does not change existing commits.
- Decide whether you are comfortable publishing your username, directory conventions, installed tools, and desktop preferences.
- Review any GitHub-only content, such as issues, pull requests, and release attachments, that will become public with the repository.

If a credential is found, revoke or rotate it before publishing and remove it from the history intended for publication. Deleting it from the latest version or adding an ignore rule does not remove earlier copies.

## When adding or changing dotfiles

- Store machine-local mise values in `~/.config/mise/config.local.toml`, outside the checkout. Keep shared Git identity settings templated and use local Git fragments for account-specific settings.
- Generate SSH keys locally. Never capture private keys, cloud credentials, authentication sessions, or shell history into the repository.
- Review the source file before running `mise dot add`, then review the captured file and staged diff before committing. Capture only configuration you intend to share.
- Keep secret values in a secret manager or local environment. If a template renders a secret, keep the rendered destination outside the checkout and source control.
- Repeat secret scanning before publishing changes and enable the pre-commit check below to catch accidental additions early.

## Betterleaks pre-commit check

Full bootstrap installs Betterleaks as a global mise tool and enables this checkout's pre-commit hook automatically. The global and repository configurations pin the same version; update both when upgrading.

For another clone, or without full bootstrap, run this once from the checkout:

```sh
mise trust
mise run hooks-install
```

The task installs Betterleaks and sets this clone's `core.hooksPath` to `.githooks`. Setup can be rerun safely. If a custom hook path or an existing local pre-commit hook is present, setup preserves it and prints a message; integrate `.githooks/pre-commit` into those hooks manually. Source archives without Git metadata skip hook setup. Hooks are enabled only for this checkout, not globally for every repository.

Each commit runs Betterleaks against staged changes using its default detection rules. Findings are redacted, and a finding or scanner failure blocks the commit. The hook requires mise on `PATH` and the pinned Betterleaks version installed. Review findings and remove secrets from the staged content before retrying.

To scan all locally available branches and tags, including earlier commits:

```sh
mise run secrets
```

Fetch any missing branches and tags before the publishing scan. The pre-commit check scans staged changes only; it does not replace a full-history review. Git hooks are local and can be bypassed, so they do not enforce checks on other contributors or on GitHub.

The root `.gitignore` excludes environment files, local mise overrides, common credential directories, and common private-key filenames and extensions. These rules are a precaution: they do not protect already tracked files, arbitrary secret filenames, or files added with `git add --force`. Check `git diff --cached` before every commit.
