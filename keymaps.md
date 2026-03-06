# Neovim Keymaps

`<Space>` = leader | [LazyVim defaults](https://lazyvim.github.io/keymaps)

---

## Index

- [Escape](#escape)
- [Claude AI](#claude-ai)
- [Navigation](#navigation)
- [Files](#files)
- [Terminal](#terminal)
- [Search & Replace](#search--replace)
- [Git](#git)
- [Editing](#editing)
- [UI](#ui)

---

## Escape

One key, always the right action.

| Mode            | Context                          | Action                                 |
| --------------- | -------------------------------- | -------------------------------------- |
| `i` / `v` / `o` | Any                              | Exit to Normal (Vim default)           |
| `c`             | Noice cmdline / search           | Cancel + dismiss Noice popup           |
| `t`             | Claude float                     | Passthrough to Claude process          |
| `t`             | Other float terminal             | Close float immediately                |
| any             | Claude — focus changes           | Auto-hides (process stays alive)       |
| any             | Toggleterm float — focus changes | Auto-closes                            |
| `t`             | Split terminal                   | Exit terminal mode (`<C-\><C-n>`)      |
| `n`             | Inside float (mini.files)        | `mini.files.close()`                   |
| `n`             | Inside other float               | Close that window                      |
| `n`             | Normal editor                    | Clear search highlight + dismiss Noice |

`<C-c>` in `n`/`i` → force `<C-\><C-n>` (guaranteed escape from any stuck state)

---

## Claude AI

| Key          | Mode            | Action                                                   |
| ------------ | --------------- | -------------------------------------------------------- |
| `<C-q>`      | `n` / `i` / `t` | Toggle panel — hide or show (process always stays alive) |
| `<leader>aa` | n               | Toggle Claude Code                                       |
| `<leader>ab` | n               | Add current buffer to context                            |
| `<leader>as` | v               | Send selection to Claude                                 |
| `<leader>ar` | n               | Resume previous session                                  |
| `<leader>ac` | n               | Continue session                                         |
| `<leader>am` | n               | Select model                                             |
| `<leader>af` | n               | Focus Claude panel                                       |
| `<leader>ay` | n               | Accept diff                                              |
| `<leader>an` | n               | Deny diff                                                |

---

## Navigation

### Splits

| Key | Action |
| --- | ------ |
