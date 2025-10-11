# Git settings

Table of Contents

1. Overview
2. Highlights
3. Adoption

---

1. Overview

- This repository includes a sample per-user Git configuration at `git/.gitconfig`.

2. Highlights

- User identity (name and email)
- Editor preference: `nano`
- Aliases: `st` (status), `co` (checkout), `br` (branch)
- `pull.rebase = true` for rebasing local changes when pulling

3. Adoption

```fish
cp ~/Projects/TL40-Dots/git/.gitconfig ~/.gitconfig
```

After copying, adjust identity values:

- `user.name`
- `user.email`
