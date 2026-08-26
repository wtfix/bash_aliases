# Bash Aliases Toolkit

A comprehensive library of intuitive shell aliases designed to simplify and streamline the command-line experience.

All-in-all ~150KB, no dependencies*, plain bash.

____________________________________________________________


## Purpose

This project aims to enhance shell productivity by providing a collection of easy-to-use, auto-completable aliases for common tasks across various operating systems and package managers.

/ To emphasize how useful long-tail commands might be used in a more efficient and organized manner.


## Key Features

- Intuitive naming conventions for easy discovery and use
- Tab-completion support for all commands and aliases


## Adding Aliases
```bash


# A long-tail command example:
$ docker run -d -p 3000:8080 -e OPENAI_API_KEY=your_secret_key -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

# Ctrl+A to the beginning of the command, and just prepend the command `al a docker-run-webui `
# Or `al a docker docker-run-webui ` - to create the alias in a special docker category (`docker.sh` will be created).
# This will create an alias for this Docker run command
# Usage: 
$ docker-<TAB>
->
$ docker-run-webui
# OR list all your docker-related aliases.
docker-run-webui       docker-run-nginx     docker-run-sometool

# Edit alias: `al e docker-run-webui` - this will open your favorite text editor right on the line with the alias to edit it.
```

To use an alias, simply start typing its prefix and press TAB to see available options.

## Installation

There are three ways to install the Bash Aliases:

1. One-liner (installs the `minimal` preset by default):
```bash
curl -fsSL https://raw.githubusercontent.com/wtfix/bash_aliases/main/install.sh | bash
```

2. Clone the repository using Git: 
```bash
git clone https://github.com/wtfix/bash_aliases.git $HOME/bash_aliases
bash $HOME/bash_aliases/install.sh
```

3. Download the latest release from the GitHub repository and unzip it to your home directory. Then, add the following to your `.bashrc` or `.zshrc`:
```bash
# Define the base path for the Bash Aliases project
export BASH_ALIASES_ROOT="$HOME/bash_aliases"

# Init Bash Aliases
if [ -e "$BASH_ALIASES_ROOT/_core/init.sh" ]; then
    source "$BASH_ALIASES_ROOT/_core/init.sh"
fi
```

## Presets

Fresh installs source a small `minimal` set (`bash.sh`, `net.sh`, `files.sh`).
The selection is per-machine and lives in the repo's `.preset` file
(e.g. `~/bash_aliases/.preset`, git-ignored):

```bash
al install            # status: current preset + enabled/disabled files
al install help       # all options
al install standard   # switch preset: minimal | standard | full
al install python     # additionally enable one category
al install -wifi      # disable one category
al install upgrade    # fetch latest framework + files
```

No `.preset` file means "source everything" (the pre-presets behavior).

### Install on a remote host

```bash
al install to user@host              # minimal preset; host fetches via curl
al install to user@host full         # full collection
al install to user@host --offline    # host has no internet: repo is copied
                                     # over ssh WITHOUT .git (read-only mirror)
al install to user@host minimal --offline --with-git
                                     # also transfer .git (asks confirmation)
```

The offline copy contains no credentials and cannot push anywhere. To also
transfer the repository history, add `--with-git` - it asks for confirmation,
since pushing from such a host would require copying your SSH write key there.
Do not use `--with-git` on untrusted hosts.

## Usage Examples

Every command has a long form (`aliases ...`) and a shorthand (`al ...`) -
both are shown below, they do exactly the same.

```bash
# List aliases and functions
$ aliases list                    # or: al l
$ aliases list net                # only names starting with 'net'   (al l net)

# Search by keyword
$ aliases search sqlite           # or: al s sqlite

# Show where a command is defined + its code
$ aliases which pp                # or: al w pp

# Add an alias
$ aliases add net wip "git status"        # or: al a net wip "git status"

# Open your configured editor right at the line of an alias or file
$ aliases edit pp                 # or: al e pp
$ aliases edit net                # opens the whole net.sh

# `edit` accepts either an alias name (opens the editor on its definition
# line) or a category/file name like `net` (opens the whole .sh file).
# Prefix an editor to override the configured one for this call: al e -zed pp

# Remove an alias / move it to another category file
$ aliases remove wip              # or: al r wip
$ aliases move wip docker         # or: al m wip docker

# Commit & push your whole collection to git
$ aliases save-to-git "Add wip"   # or: al sv "Add wip"

# Presets and remote installation
$ aliases install standard            # or: al i standard
$ aliases install python              # enable one more category
$ aliases install upgrade             # fetch latest version
$ aliases install to me@vps full      # or: al i to me@vps full
```

## Getting Started

Restart your shell or run `source ~/.bashrc` (or `~/.zshrc`)

Since then, you may use alias `rehash` for `source ~/.bashrc` to update the list of available aliases.

Start exploring with tab completion!

## Contributing

Just fork it for yourself.

## License

This project is licensed under a Do WTF You Want License.
