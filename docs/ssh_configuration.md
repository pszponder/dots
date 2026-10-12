# Configuring SSH Keys

## Configure remote hosts

Use `~/.ssh/config` to give remote servers a stable alias and select connection options such as the user, port, and identity. This is useful for interactive SSH, `scp`, `rsync`, and tools that invoke SSH.

```sshconfig
# ~/.ssh/config
Host <ssh_alias_name>
    HostName <remote_server_ip>
    User <username_for _server>
    IdentityFile ~/.ssh/<path_to_your_private_key>

Host app-prod
    HostName 203.0.113.10
    User deploy
    Port 2222
    IdentityFile ~/.ssh/servers/app-prod
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Replace the example hostname, user, port (OpenSSH defaults to 22 if not specified), and key path for each server. Then connect with `ssh app-prod`, copy with `scp file app-prod:/path/`, or use the alias as an `rsync` destination.

`IdentitiesOnly yes` makes OpenSSH use the identity declared for that host instead of also offering keys held by `ssh-agent`. This prevents the wrong account being selected and avoids "too many authentication failures" when the agent has several keys.

Protect the directory, configuration, and private keys:

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config ~/.ssh/servers/app-prod
```

## Generate new SSH key pairs

Refer to the `$HOME/.local/bin/sshkeygen` script to help create an ssh key pair.

```sh
sshkeygen [-t ed25519|rsa] [-d key_dir] [-n key_name] [-c comment] [-a|-A] [-q]
```

| Flag | Description                              | Default               |
| ---- | ---------------------------------------- | --------------------- |
| `-t` | Key type (`ed25519` or `rsa`)            | `ed25519`             |
| `-d` | Directory to store the key               | `~/.ssh`              |
| `-n` | Key filename                             | `id_<type>`           |
| `-c` | Key comment (e.g. email or purpose)      | none                  |
| `-a` | Add key to the current `ssh-agent` | prompts interactively |
| `-A` | Skip adding to an agent | disabled |
| `-q` | Skip clipboard copy | disabled |

Omitted directory, filename, and comment values are prompted for. Key type defaults to Ed25519. `-a` and `-A` skip the agent choice prompt; key generation and `ssh-add` may still ask for a passphrase. The script will:
- Create `key_dir` (`chmod 700`) if it doesn't exist, and refuse to overwrite either an existing private or public key
- Generate the key pair and set `chmod 600`/`644` on the private/public key respectively
- Optionally add the private key to `ssh-agent` (using the macOS Keychain if run on macOS)
- Copy the public key to your clipboard if a supported clipboard utility is found (`cb`, `pbcopy`, `xclip`, `xsel`, `wl-copy`, or `clip.exe`), otherwise print it to the terminal

You should create a new SSH key for each service which you wish to connect to via SSH
- Ex. If you have a GitHub and Bitbucket account, you should have a separate SSH key pair for each service.
- You will also need to create an ssh key for any remote machines you wish to connect to (assuming you want to use an ssh key instead of a username and password, which is recommended)

## Bootstrap default SSH keys

The final bootstrap hook in [`mise.toml`](../mise.toml) runs [`scripts/bootstrap/create_ssh_keys.sh`](../scripts/bootstrap/create_ssh_keys.sh) on both profiles, after packages and dotfiles are installed:

```sh
mise -E workstation bootstrap
# Or: mise -E server bootstrap
```

Edit `DEFAULT_KEYS` in the script to customize the default set:

- `~/.ssh/default`: general-purpose key.
- `~/.ssh/github/pszponder/personal`: personal GitHub account key.

Existing private keys are preserved. An orphaned public key or a non-regular private-key path causes an error for manual resolution. Missing keys require a terminal and prompt for a passphrase. Bootstrap skips clipboard and agent operations, and never stores private keys in the repository. Rerunning bootstrap creates newly declared keys and keeps existing ones.

To load a generated key, use an existing agent in your shell or start one:

```sh
eval "$(ssh-agent -s)"  # Only if your session does not already provide an agent
ssh-add ~/.ssh/github/pszponder/personal
```

Generating a key does not register it with GitHub or any remote host. Follow the steps below to authorize its public key.

## Add the public key to your account / service / VM

### Add public key to account / service

Copy the contents of the public key file (ends in `.pub`) to your account / service

### Add public key to VM

Copy the contents of the public key file into the VM's `authorized_keys` file

```sh
# Login to your VM first

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "<your_public_key_contents>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Alternatively

```sh
# From your local machine, copy the public key directly to the VM
ssh-copy-id -i ~/.ssh/<path_to_your_public_key> <username>@<remote_ip>
```

After completing these steps, you should be able to SSH into your VM:

```sh
ssh <username>@<remote_ip>

# Or, if you configured an alias in ~/.ssh/config,
ssh <ssh_alias_name>
```

## Add the private key to your computer's git config

This step is optional but recommended if you are using multiple remote repo accounts (ex. a personal and work GitHub account)

This specific method will use folder-specific identities
- Meaning that anything in a given directory will use your specified ssh config

Here is an example directory hierarchy:

**~/**
- **repos/** (where all your repos go)
    - **github**
        - **pszponder**
            - **repo1**
            - **repo2**
            - ...
    - **bitbucket**
    - **gitlab**
    - ...
- **sandbox/** (place to store experiments)
- **courses/** (place course materials here)
- **resources/** (books, cheat sheets, etc.)

This is what your global gitconfig (`~/.config/git/config`) should look like
```txt
# ~/.config/git/config

# Include for all .git projects under ~/repos/github/pszponder
# Copy this pattern for any other git repos, making sure to change the gitdir and path
[includeIf "gitdir:~/repos/github/pszponder/**"]
path = ~/.config/git/github_pszponder

# Add other global gitconfig settings here ...
```

Git configuration is not deployed by the current bootstrap. The following is an optional example: `~/.config/git/github_pszponder` can contain the Git identity collected through mise variables and the SSH key for repositories matched by the `includeIf` rules above. Create a separate fragment and include rule for each future host or account that needs a different identity or SSH key.

```txt
# ~/.config/git/github_pszponder

[user]
    email = <git_email>
    name = <github_username>

[core]
    sshCommand = "ssh -i <PATH_TO_YOUR_PERSONAL_PRIVATE_KEY> -o IdentitiesOnly=yes"
```

`core.sshCommand` is enough for Git repositories matched by the include rule; it does not require a `Host github.com` entry in `~/.ssh/config`. Keep the SSH config for services and remote servers that need reusable connection settings.

## Resources / References

- [Using multiple GitHub accounts without login](https://blog.omkarpai.net/posts/multiple-git-identities/)
- [GitGuardian - 8 Easy Steps to Set Up Multiple GitHub Accounts](https://blog.gitguardian.com/8-easy-steps-to-set-up-multiple-git-accounts/)