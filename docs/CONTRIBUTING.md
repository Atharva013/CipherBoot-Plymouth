# Contributing to CipherBoot Plymouth Theme

Thank you for considering contributing! Every pull request — from a typo fix to a new distro — is valued.

---

## Ways to Contribute

- 🐛 **Report bugs** — use the Bug Report issue template
- 💡 **Request features** — use the Feature Request issue template
- 🖥️ **Add distro support** — test on your distro and submit a PR updating `detect_distro.sh`
- 🎨 **Create a new variant** — design a new visual style and submit theme + `.plymouth` file
- 📝 **Improve documentation** — fix typos, clarify steps, add screenshots

---

## Currently Supported Distros

**Ubuntu-based:** Ubuntu, Zorin OS, Pop!_OS, Linux Mint, elementary OS  
**Arch-based:** Arch Linux, EndeavourOS, Manjaro, Garuda Linux, CachyOS

Want to add your distro? Update `scripts/detect_distro.sh` with your distro's ID from `/etc/os-release`.

---

## Branch Naming

Always work on a branch, never directly on `main`:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
# or
git checkout -b distro/add-fedora-support
```

---

## Pull Request Rules

- One feature/fix per PR
- Test on at least one supported distro before submitting
- Include a before/after screenshot or GIF if it's a visual change
- Update relevant docs if your change affects installation or usage

---

## Code Style (Shell Scripts)

- Use `#!/usr/bin/env bash` shebang (not `/bin/sh`)
- Always quote variables: `"$VARIABLE"` not `$VARIABLE`
- Use `set -e` at the top of every script
- Colour codes: use the `CYAN`, `GREEN`, `RED`, `RESET` variables already defined
- Comment every logical section with a `# ─── Section Name ──` header

---

## Code Style (Python)

- Use type hints where sensible
- Follow PEP 8
- Use `pathlib.Path` for file operations
- Include docstrings for all functions

---

## Testing Checklist (Before Opening a PR)

- [ ] Ran `shellcheck install.sh` — no errors
- [ ] Ran `bash scripts/validate.sh` — no errors
- [ ] Tested install on a supported distro (Ubuntu or Arch family)
- [ ] Tested preview.sh — no zombie processes
- [ ] Tested uninstall — system default theme restored correctly
- [ ] GRUB config restored correctly on uninstall
- [ ] README still accurate after your change

---

## Questions?

Open a [GitHub Issue](https://github.com/Atharva013/CipherBoot-Plymouth/issues) — happy to help!
