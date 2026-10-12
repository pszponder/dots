# Home Directory Structure

`mise -E workstation bootstrap` (or `-E server`) creates these directories from `[bootstrap.directories]` in [`config.toml`](../dots/.config/mise/config.toml). Existing directories and their contents are preserved.

```
~/
├── repos/                    # Source-controlled projects and repositories
│   └── github/
│       └── pszponder/        # Personal GitHub repositories
│
├── resources/                # Learning materials, reference material, and knowledge
│   ├── courses/               # Course materials, tutorials, and learning programs
│   ├── books/                 # Books, ebooks, and book-related material
│   ├── datasets/               # Datasets and data used for learning, analysis, or experimentation
│   ├── cheatsheets/            # Quick-reference guides and condensed technical references
│   └── notes/                  # Personal notes, summaries, and distilled knowledge
│
└── scratch/                  # Temporary, disposable work and quick experiments
```

To add or remove a default directory, edit `[bootstrap.directories]` in `dots/.config/mise/config.toml`. Removing a declaration leaves the directory on disk. SSH directories are also declared with mode `0700`.
