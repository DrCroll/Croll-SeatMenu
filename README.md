## Croll-CarSeats - discord.gg/DBqCZjZ8VN

In-game seat picker for **FiveM**. While you are inside a vehicle, open a small side UI, see which seats are free or occupied, and warp to an empty seat. Uses **ox_lib** for notifications (`lib.notify`). Client-only resource (no server component).

---

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib) installed and ensuring before this resource (`ensure ox_lib` before `ensure Croll-CarSeats`).

---

## Installation

1. Place the `Croll-CarSeats` folder in your `resources` tree.
2. In `server.cfg` (after `ox_lib`):

   ```
   ensure Croll-CarSeats
   ```

3. Restart the server or refresh the resource.

---

## Usage

| Action | Detail |
|--------|--------|
| Open / close menu | `/seatmenu` (toggle) |
| Close from UI | **Esc** or the **×** button |
| Refresh list | **Refresh** (e.g. after passengers move) |

You must **be seated in the vehicle**. The seat list follows the vehicle model’s passenger layout (does not expose invalid “extra” seat indices).

---

## Configuration

Edit [`config.lua`](config.lua):

| Setting | Purpose |
|---------|---------|
| `Config.CommandSuggestion` | Chat hint text for `/seatmenu`. Set to `nil` or `''` to use the built-in default. |
| `Config.UI` | CSS-oriented strings (hex / `rgba` / shadows) sent to the NUI once per **open**. Only documented keys under `Config.UI` are applied; malformed values are skipped. |

After changing colors, reopen the seat menu to see updates.

---


## Permissions

Access is **everyone**: the command `seatmenu` is registered with restricted flag `false`. To lock it behind ACE or a framework, extend `RegisterCommand` in [`client/main.lua`](client/main.lua) as needed.

---
