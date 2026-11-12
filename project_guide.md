# Chess: project guide

A chess game in Godot, built so that **variants** can be made by swapping data and small rule functions instead of rewriting the game. Examples: atomic ("nuke") chess, 4-player chess, games with fewer pieces, custom setups.

**Plan:** standard chess first, built the variant-friendly way from the start. Variants come after.

**About this guide:** this is my reference for the project: setup, conventions, how the code is organised, decisions, progress and lessons learned. I read it to pick up where I left off. Claude keeps it up to date, so it stays complete and consistent. Notes for AI assistants are in the last section.

---

## Setup

|            |                                                                                                                                 |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Engine     | Godot 4.7 stable, **Compatibility** renderer (runs on low-spec hardware)                                                        |
| Platforms  | Desktop **and mobile**: everything must work with a mouse and with touch (taps)                                                 |
| Resolution | 1920 × 1080 viewport, stretch mode `canvas_items` / `expand`. Test window 1280 × 720                                            |
| Plugin     | Scalable Vector Shapes 2D 3.3.2 (`addons/curved_lines_2d`), for vector piece art                                                |
| Art        | Inkscape, saved as SVG                                                                                                          |
| Editor     | 2D Editor Panning Scheme = Scroll Pans (scroll = up/down, Shift+scroll = left/right, Ctrl+scroll = zoom)                        |
| Later      | Maybe move to Blazium once its Godot 4.8-based version is out. A project can only move to a _newer_ engine version, never back. |

---

## Folders

```
chess/
├── README.md            ← the repo's front page on GitHub
├── LICENSE.md           ← Prosperity Public License 3.0.0
├── CREDITS.md           ← third-party notices (plugin, Godot, Cburnett's BSD notice)
├── project_guide.md     ← this file
├── main.tscn            ← the main scene
├── scenes/pieces/       ← one scene per piece type (rook.tscn, knight.tscn, ...)
├── scripts/             ← all .gd scripts
│   └── rules/           ← rule scripts (standard chess + one per variant that changes rules)
├── sprites/pieces/      ← piece art the game uses (.svg), exported from art_source
├── art_source/pieces/   ← Inkscape working files (has .gdignore, so Godot ignores it)
├── variants/            ← one .tres file per chess variant (standard.tres, ...)
└── addons/              ← plugins, don't edit
```

---

## Naming conventions

Godot's official style, so my code looks like the docs, tutorials and add-ons.

| What                                                  | Style                                 | Example                                              |
| ----------------------------------------------------- | ------------------------------------- | ---------------------------------------------------- |
| Files and folders (scripts, scenes, SVGs, everything) | snake_case, all lowercase             | `board.gd`, `main.tscn`, `sprites/pieces/knight.svg` |
| Nodes in the scene tree                               | PascalCase                            | `Board`, `Pieces`                                    |
| `class_name`                                          | PascalCase                            | `class_name Board`                                   |
| Variables and functions                               | snake_case                            | `selected_piece`, `square_to_position()`             |
| Constants                                             | CONSTANT_CASE                         | `SQUARE_SIZE`                                        |
| Enums                                                 | PascalCase name, CONSTANT_CASE values | `enum Result { NONE, WIN, DRAW }`                    |
| Signals                                               | snake_case, past tense                | `piece_moved`, `turn_ended`                          |
| Private (only used inside its own script)             | starts with `_`                       | `_selected_piece`                                    |

- **Why all-lowercase files:** Windows ignores letter case but exported games don't. `Knight.svg` vs `knight.svg` can work in the editor and break in the exported game.
- **Rename and move files inside Godot's FileSystem dock**, not Windows Explorer, so references update. A rename that only changes capitals may need a temporary name in between (`Knight.svg` → `knight_tmp.svg` → `knight.svg`).
- A script and its scene share a name: `board.gd` + `board.tscn`, root node `Board`.
- True/false variables read like yes/no questions: `is_selected`, `has_moved`.
- Code is in English, with US spelling `color` to match Godot's own API.
- "**rook**", not "castle".
- Indent with tabs (Godot's default). Don't mix tabs and spaces.
- Exception: files that tools look for by exact name keep that name (`CLAUDE.md`, `README.md`).

---

## Art pipeline

### Drawing a piece

- Inkscape page: **100 × 100 px**, which is exactly one board square.
- **Fit the piece to the page *without* its outline**, centred, then add the 1 mm outline. The outline then sticks out about 2 px past the page edge. That's expected: browsers cut it off, but Godot imports it. (Fitting first is easier because with scale stroke width off, Inkscape only corrects the outline *after* scaling, so snapping grabs the wrong spot while you drag.)
- **No margin in the SVG.** The gap between the piece and the edge of its square comes from `piece_scale` in the game (see [The piece scene](#the-piece-scene-scenespiecespiecetscn)).
- Use only two colours: **white fill `#ffffff`** and **black outline `#000000`**. The game recolours them per side, so one file works for every side.
- Save as `sprites/pieces/<piece>.svg` (lowercase).
- **Use the same outline width on every piece** so the set looks consistent (the pawn uses 1 mm). Inkscape sometimes changes outline widths by itself when shapes are resized, converted or edited, so:
  - turn off **scale stroke width**: the toggle on the Select tool's toolbar, or Edit → Preferences → Behavior → Transforms → Scale stroke width
  - as a last step before exporting, select every shape on the page, open **Fill and Stroke** (Ctrl+Shift+F) → **Stroke style**, and type the width once. It applies to every selected shape.
- **Working file vs game file.** The working file (in `art_source/pieces/`) can hold backup shapes off the page. The game file is exported from it: select (highlight) every shape on the page, then Export as Plain SVG with **Export Selected Only** ticked, to `sprites/pieces/<piece>.svg`. Only the selected shapes are exported, and the file keeps the 100 × 100 page.
- `art_source/` has an empty `.gdignore` file in it, so Godot ignores the working files, but they're still part of the project and the GitHub repo.

### Piece sizes compared to each other

Right now the king, rook and pawn are all fitted to the full page, so they're all the same height. Real chess sets (and Cburnett's diagrams) make the pawn shorter and the king tallest. **Open choice:** keep them all the same size (a stylised look), or keep the relative sizes by fitting only the tallest piece (the king) to the page and drawing the others at the same scale, shorter, centred horizontally.

### The piece scene (`scenes/pieces/<piece>.tscn`)

```
Rook                 (Node2D, script: scripts/piece.gd)  ← placed at the centre of its square
└── SyncedSVGRoot    (position -50, -50)                 ← made by the plugin, keeps the art synced with the .svg
	└── Rook                                             ← imported art: Polygon2D = fills, Line2D = outlines
```

- Import with the plugin's **Import SVG File** tab, using these settings:

| Option                                        | Setting     | What it means                                                                                                                                                                  |
| --------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Automatic Synchronization with SyncedSVGRoot  | **on**      | keeps the scene in sync with the .svg file                                                                                                                                     |
| Import as ScalableVectorShape2D               | **on**      | each shape gets the plugin's own node, which remembers the curves so they can be edited or animated in Godot. The plugin advises keeping it on (off prints errors)             |
| Use Line2D for Strokes                        | **on**      | outlines become `Line2D` nodes. **`piece.gd` relies on this:** Polygon2D = fill, Line2D = outline. With it off, outlines would be Polygon2D too and get the fill colour |
| Flag on antialiased for Polygon2D and Line2D  | your choice | smooth edges, see [Antialiasing](#antialiasing-smooth-edges) below                                                                                                             |

- The SyncedSVGRoot position of (-50, -50) moves the page's centre onto the scene's origin, so a piece placed at a square's centre sits in the middle of it.
- **Piece size on the board:** `board.gd` has `@export var piece_scale := 0.9`, and each placed piece gets `scale = Vector2.ONE * piece_scale`. Because the piece scene's origin is its centre, scaling keeps it centred on the square. With the outline sticking out ~2 px, a piece is ~104 px wide at scale 1, so 0.9 leaves a ~3 px gap on each side of a 100 px square (0.85 leaves ~6 px). Later this can become a player setting: change `piece_scale` and update the scale of every node in `Pieces`.
- A quick way to make a new piece scene: duplicate an existing one, rename its root node, select SyncedSVGRoot and change **Svg Resource Path** to the new SVG.

### Changing art later

- Edit and save the .svg in Inkscape, then open that piece's scene in Godot and it reimports. If you only see a warning, select SyncedSVGRoot and press **Reimport** in the Inspector.
- **Never edit the imported shapes inside Godot.** The next reimport replaces them.
- SyncedSVGRoot remembers the import settings. Changing one of them in its Inspector (for example **Is Aa** or **Is Svs**) reimports the piece with the new setting.

### Colours

Each side has a fill colour and an outline colour (set in the variant). `piece.gd` sets every `Polygon2D` to the fill colour and every `Line2D` to the outline colour. This only works because strokes are imported as Line2D (see the import settings above).

### Antialiasing (smooth edges)

Antialiasing softens the "staircase" pixels along diagonal and curved edges. Not urgent: decide once the real art exists and you can see whether the edges bother you.

- **Project-wide (the usual way):** Project Settings → Rendering → Anti Aliasing → Quality → **MSAA 2D**. Code can change it while the game runs (`get_viewport().msaa_2d`), so it can become a player graphics setting. **Catch:** MSAA 2D is reported not to work with the **Compatibility** renderer this project uses. Easy to test: turn it on, run the game and compare the edges.
- **Per shape:** the `antialiased` property on each Polygon2D and Line2D. For an existing piece, tick **Is Aa** on its SyncedSVGRoot. A player setting can still control this: a function in `piece.gd` that switches `antialiased` on every shape, the same way `set_colors` works.
- The plugin's Project Settings tab also has "Add Line2D antialiasing texture for Compatibility mode".

---

## Architecture

**Goal:** a new variant is mostly **new data**, plus overriding **only the rule functions that are different**.

### The four parts

| Part          | What it is                    | Knows about                                                                  | Never does                            |
| ------------- | ----------------------------- | ---------------------------------------------------------------------------- | ------------------------------------- |
| **Variant**   | a `.tres` file in `variants/` | board shape, starting layout, sides (colours, direction), which Rules to use | contain logic                         |
| **GameState** | a plain data object           | what's on each square, whose turn it is, the move history                    | draw anything, or decide what's legal |
| **Rules**     | a script in `scripts/rules/`  | how pieces move, what's legal, what a move does, when the game ends          | touch nodes or sprites                |
| **View**      | Board, piece scenes, input    | drawing, clicks, animation                                                   | decide rules (it asks Rules)          |

`main.gd` connects them. It loads a variant, builds the GameState from the variant's layout and tells the view to show it.

**Two dictionaries, two jobs:**
- `GameState.squares` (`Vector2i` → `PieceData`) is the game itself. The rules read and change it, and can copy it to test a move without anything changing on screen.
- `Board.piece_nodes` (`Vector2i` → `Piece` node) only tracks which node is drawn on which square. It never decides anything.

**How the screen follows the state:**
- **Now:** after every change, `Board.show_state` deletes all piece nodes and creates them again from the state. The screen can never disagree with the game, and special moves (castling, en passant, promotion, atomic explosions) and future variants need no extra screen code. It costs a few milliseconds per move, which is nothing for a turn-based game. Downside: pieces jump instead of sliding.
- **Later, for animations:** slide the moved piece's node (the Move says from and to; `piece_nodes` finds the node), then *sync* the rest by comparing `piece_nodes` with the state and adding, removing or swapping whatever doesn't match. Only `board.gd` changes.

**Data objects in Godot:** a `Node` lives in the scene (draws, gets input). A `Resource` is data saved as a file and edited in the Inspector (`ChessVariant`, `Side`). A `RefCounted` is plain data that only exists while the game runs and is deleted automatically when nothing uses it (`GameState`, `PieceData`, later `Move`).

**A move from start to finish:**

1. The player clicks a piece. The view asks `rules.get_legal_moves(state, square)` and highlights those squares.
2. The player clicks a highlighted square, and `rules.apply_move(state, move)` changes the state.
3. The view updates to match the state, and `rules.get_winner(state)` checks whether the game is over.

### Rules are small functions that can be overridden

`scripts/rules/rules.gd` (`class_name Rules`, `extends Resource`) contains **standard chess**. A variant's rules extend it and override only what's different:

```gdscript
class_name AtomicRules
extends Rules

func on_capture(state: GameState, move: Move) -> void:
	# Explosion: remove the capturing piece and every non-pawn piece around the captured square
	...
```

Planned functions. Names can change while building, but each function keeps one job:

| Function                         | Job                                    | In standard chess                              |
| -------------------------------- | -------------------------------------- | ---------------------------------------------- |
| `get_piece_moves(state, square)` | where a piece could go, ignoring check | the movement patterns below                    |
| `is_move_legal(state, move)`     | removes forbidden moves                | you can't leave your own king in check         |
| `get_legal_moves(state, square)` | the two above combined                 | usually not overridden                         |
| `apply_move(state, move)`        | changes the state                      | move, capture, castling, en passant, promotion |
| `on_capture(state, move)`        | extra effects of a capture             | nothing                                        |
| `get_next_side(state)`           | whose turn is next                     | the other player                               |
| `get_winner(state)`              | is the game over, and who won?         | checkmate wins, stalemate is a draw            |

- **Rules never store the game.** Every function receives the state as a parameter. That lets the rules try a move on a _copy_ of the state, which is how check detection works.
- Rules extend `Resource`, so they can have **settings** (`@export` variables) that each variant sets in the Inspector, for example `@export var explosion_radius := 1`.

**Movement patterns.** Most pieces are a list of directions plus whether they slide:

| Piece  | Directions              | Movement                                                                                                                     |
| ------ | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Rook   | 4 straight              | slides until blocked                                                                                                         |
| Bishop | 4 diagonal              | slides until blocked                                                                                                         |
| Queen  | all 8                   | slides until blocked                                                                                                         |
| King   | all 8                   | one step                                                                                                                     |
| Knight | the 8 L-shapes (±1, ±2) | jumps, ignores pieces in between                                                                                             |
| Pawn   | its own function        | forward = its side's direction, 2 steps on its first move, captures diagonally forward, en passant, promotes at the far edge |

A new piece type only needs a new letter, a movement pattern and its art.

### The variant files

- `scripts/side.gd`: `class_name Side`, extends Resource
- `scripts/chess_variant.gd`: `class_name ChessVariant`, extends Resource. Not `Variant`, which is a built-in Godot type.

| ChessVariant field | Meaning                                                                               |
| ------------------ | ------------------------------------------------------------------------------------- |
| `display_name`     | shown in menus                                                                        |
| `sides`            | `Array[Side]`, in turn order                                                          |
| `layout`           | the starting position as text (see below). The board's size and shape come from this. |
| `rules`            | which Rules to use (added once Rules exists)                                          |

| Side field                    | Meaning                                                               |
| ----------------------------- | --------------------------------------------------------------------- |
| `letter`                      | used in the layout: `w`, `b`, ...                                     |
| `forward`                     | direction its pawns move: white `(0, -1)` = up, black `(0, 1)` = down |
| `fill_color`, `outline_color` | piece colours                                                         |

### Layout format

One line per row, top row first, squares separated by spaces. Each square is two characters: **side letter + piece letter**. `..` means an empty square and `xx` means the square isn't part of the board.

Standard chess:

```
bR bN bB bQ bK bB bN bR
bP bP bP bP bP bP bP bP
.. .. .. .. .. .. .. ..
.. .. .. .. .. .. .. ..
.. .. .. .. .. .. .. ..
.. .. .. .. .. .. .. ..
wP wP wP wP wP wP wP wP
wR wN wB wQ wK wB wN wR
```

Piece letters use standard chess notation: **K** king, **Q** queen, **R** rook, **B** bishop, **N** knight, **P** pawn.

`xx` allows boards that aren't rectangles, like 4-player chess's 14 × 14 board with the corners cut off.

### Rules of thumb (for future me)

- **Never hard-code 8, 2 players, or white/black** in game logic. Board size, shape and sides come from the variant.
- Squares are `Vector2i(col, row)`, and `(0, 0)` is the top-left square.
- A side is an **index** (0, 1, 2, 3, ...), not `is_black`. Turn order is the order of the variant's `sides`.
- "Forward" comes from the side, never from a hard-coded +1 / -1.
- The board is a Dictionary from `Vector2i` to piece. A value of `null` means an empty square, and a square missing from the dictionary isn't on the board.
- Logic never touches nodes, and nodes never decide rules.
- **One rule = one small function**, so a variant can override exactly one thing.
- Starting positions are data, not code.

### How variants map onto this

| Variant                                       | What to make                                                                                                                                               |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fewer pieces / custom setups                  | Duplicate `standard.tres` and edit the layout. **No code.**                                                                                                |
| Double-move knight (idea): a knight may jump twice in one turn | Override `get_piece_moves` for the knight. |
| King of the Hill (win by reaching the centre) | Override `get_winner`.                                                                                                                                     |
| Atomic ("nuke") chess                         | Override `on_capture` (the explosion), `is_move_legal` (you can't blow up your own king) and `get_winner` (a king exploded).                               |
| 4-player chess                                | A 14 × 14 layout with `xx` corners and 4 sides, each with its own forward direction. Override `get_next_side` (skip players who are out) and `get_winner`. |
| New piece types                               | A new letter, a movement pattern and an SVG.                                                                                                               |

---

## Status

- [x] Project setup, plugin, naming conventions
- [x] Board drawing (`scripts/board.gd`). To do: centre it (Board node position 560, 140 in `main.tscn`), read the size from the variant instead of 8, use `Vector2i`, remove the empty `_ready` / `_process`
- [x] Piece scenes for all 6 pieces, plus `scripts/piece.gd` (colouring)
- [x] `Side` + `ChessVariant` scripts, and `variants/standard.tres`
- [x] `main.gd`: load the variant and place the pieces from the layout
- [x] `main.gd`: colour pieces from their Side (`find_side`, with `push_error` when nothing matches)
- [x] Piece letter table moved into `chess_variant.gd` (`@export var piece_names: Dictionary[String, String]`)
- [x] Clean-up done: `print`s, empty `_process` / `_ready`, `break` after `return`, `find_side` parameter renamed to `letter`
- [x] Return types on `place_one_piece` / `find_side`, typed variables, `piece.gd` comment line removed
- [ ] Clean-up still to do:
  - unknown piece letters: `if piece_name == null` never runs (a `String` can't be null, and the lookup errors first). Use `variant.piece_names.get(piece_code[1], "")` and check for `""`, or check `.has()` first
  - `side` error is reported twice: keep the `push_error` in `find_side`, and only `return` in `place_one_piece`
  - `_ready() -> void`, `find_side(letter: String)`, remove the `#Board.position` comment
  - centre the board (Board position 560, 140, in the scene or in code)
- [ ] Restructure: placing piece nodes moves to `board.gd` (`add_piece`), reading the layout moves to `game_state.gd`. Do this before movement
- [ ] **Rules, in build order:**
  1. GameState: board as a Dictionary (`Vector2i` → piece data, `null` = empty, missing = not on the board), whose turn it is. Layout reading moves out of `main.gd`; the board shows pieces from the state. No visible change.
  2. Moves for the bishop, rook, queen and king (ignoring check), plus tap/click to select, dots on the legal squares, tap a dot to move
  3. Knight, then the pawn (forward only, double first move, diagonal capture, en passant): I try these myself
  4. Check: "is this square attacked by side X?" + throw away moves that leave your own king attacked
  5. Castling (my turn to try), promotion, checkmate and stalemate
- [ ] Real art: king, rook and pawn done. Queen in progress (only the crown so far). Bishop and knight are still rook placeholders
- [x] `piece_scale` (default 0.9) on Board, applied when placing pieces. Later: a player setting
- [ ] Decide: same height for every piece, or keep relative sizes (see "Piece sizes compared to each other")
- [ ] Publishing on GitHub: README.md, LICENSE.md (with the repo link) and CREDITS.md done, first commit made locally ("Initial commit", Duncan Louw <duncan.louw4@gmail.com>). To do: publish / push to https://github.com/DuncanLouw/chess
- [ ] First variant

---

## Notes and gotchas

Things that tripped me up, so I don't repeat them.

- **Layout codes:** `code[0]` is the side letter, `code[1]` is the piece letter (`"wK"` → `w` + `K`).
- **Code that does something has to be inside a function.** Outside functions, a script can only declare things (`var`, `const`, `@export`, `func`).
- **Scripts that `extends Resource` are data files** (like a form with blanks). They don't run by themselves, so `_ready()` and `$Node` don't work in them. Only scripts on nodes can do that.
- **Make silent failures loud.** When a lookup finds nothing (no matching side, unknown piece letter), call `push_error(...)` instead of quietly carrying on. Otherwise the bug only shows up as "something looks wrong".
- **Folder and file names must match the paths in code exactly** (`scene/` vs `scenes/` broke loading once).
- `Variant` is a built-in Godot type, so it can't be used as a `class_name` (that's why it's `ChessVariant`).
- `"%s" % value` fills `value` into the `%s` blank in the text. Only needed when the text has a blank.
- New piece scenes come out white with a black outline until `set_colors` runs. If every piece looks white, `set_colors` probably never ran.
- Code after a `return` never runs (for example a `break` right after `return`).
- A function with a return type (`-> Side`) must return something on every path, so add `return null` at the end when nothing was found.
- Report an error in the function that does the lookup (`find_side`), not in every place that calls it. Callers just check for `null` and stop.
- **Check detection is cheap:** one move function is used for the dots, for check and for checkmate. A few thousand dictionary lookups per click is well under a millisecond, so no clever shortcuts are needed.
- **Pawns are the exception:** they move straight forward but attack diagonally, so "squares a pawn attacks" isn't the same as "squares it can move to".
- **Local vs member variables:** a `var` inside a function is created fresh on every call and thrown away afterwards. Data that must stay (like a dictionary) is a member variable, declared at the top of the script outside any function. (Godot's "singletons" are Autoloads, global nodes; not needed here.)
- A typed `String` can never be `null`. For a dictionary key that might be missing, use `.get(key, "")` and check for `""`, or check `.has(key)` first.
- **Inkscape's page is only a window.** The importer takes every shape in the file, even ones off the page, and "Plain SVG" doesn't remove them. Export with Export Selected Only (area: Page) instead.
- Exported game files must keep the 100 × 100 px page. Open the .svg in a text editor and check for `width="100" height="100"` if a piece looks the wrong size.

---

## Publishing (GitHub)

- **Repo = the `chess` folder** (the one with `project.godot`), not the whole Projects folder.
- **Email:** commits use my professional email (duncan.louw4@gmail.com, the one on my CV), so "Keep my email addresses private" stays **off** on GitHub. The email must be added and verified under GitHub → Settings → Emails, or commits won't link to my profile.
- **Before every push:** check the file list. Anything pushed stays in the history, even if it's deleted later.
- **Commit:** `.import` and `.uid` files (Godot needs them), `addons/` (the plugin, with its LICENSE file). **Ignored:** `.godot/` (already in `.gitignore`).
- **Screenshots** for the README go in a folder with an empty `.gdignore` file (e.g. `docs/`), so Godot doesn't import them.
- **Running from source:** install Godot 4.7, open `project.godot`, press F5. No compiling needed.
- **Releases:** tag a version (`v0.1`) and attach an exported build. Exporting needs the export templates (Editor → Manage Export Templates). Builds must include Godot's license notice (credits screen or a text file).
- **README:** written. Later: add a screenshot or GIF and the controls once there's gameplay, and keep the Status line current.
- **Credits:** in README.md (short) and CREDITS.md (full notices, including Cburnett's BSD text). Optional, not added: a note about AI help.
- **License (decided): Prosperity Public License 3.0.0** in LICENSE.md. Free for noncommercial use, a 30-day commercial trial, and after that a commercial licence by agreement. The README says "Contact me for a commercial licence: duncan.louw4@gmail.com".
  - The same license covers my code and my art. Cburnett's originals stay under his own licenses; his credit and BSD notice are in CREDITS.md.
  - **Extra permissions (in the README):** any educational use (including schools that charge fees, and paid courses), and videos or streams that earn money (e.g. YouTube) are allowed without asking. The license already counts schools as noncommercial ("educational institution ... regardless of the source of funding"); the README makes the rest clear.
  - Godot and the plugin keep their own MIT licenses. My license only covers my files.
  - A noncommercial license is "source-available", not "open source", so don't call the project open source.

---

## Decisions

- **Board drawn in code** (`_draw`), not an image: the colours are settings, the board can be any size, and highlights use the same code.
- **Pieces as vector nodes** through the plugin, so they stay sharp at any zoom. Fallback: Sprite2D + the shader below.
- **One SVG per piece type.** Each side's colours are applied in the game.
- **The board rebuilds its piece nodes from the state after every move** (simple and always in sync). Animations later: slide the moved piece, then sync the rest.
- **The SVG page and the board square are both 100 × 100.** Pieces fill the page (outline slightly past it); the gap to the square's edge is set in code with `piece_scale`, so it can become a game setting.
- **Plugin import keeps "Import as ScalableVectorShape2D" on**, as the plugin advises. (An earlier version of this guide said off, which was wrong.)
- **License: Prosperity Public License 3.0.0**, with commercial licences by agreement.
- **"Rook", not "castle"**, to avoid clashing with the castling move.
- **Official Godot, not Blazium** for now (Blazium is still based on Godot 4.3). Revisit when its 4.8-based version ships.

---

## Appendix: two-colour shader (fallback for Sprite2D pieces)

For pieces imported as normal textures instead of vector nodes. White in the image becomes the fill colour, black becomes the outline colour, and grey edges blend between the two.

```glsl
shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(outline_color.rgb, fill_color.rgb, tex.r), tex.a);
}
```

Use one ShaderMaterial per side (`white_side.tres`, `black_side.tres`), so changing a material recolours that whole side.

---

## For AI assistants

- I'm learning Godot. **How we work on code:** for things that are just "how does Godot do X" (syntax, built-in functions, nodes, input), give me the code and tell me exactly which file and where to put it, and I type it in myself. **Stop and let me try** whenever a part needs real problem solving or thinking (not just a lookup). Don't change code files yourself unless I ask. When reviewing, tell me _why_, not just what.
- Keep each step small and testable: after each step I should be able to run the game (F5) and see that it works, then commit.
- Follow the naming conventions and architecture rules in this file.
- Ignore `.godot/` (Godot's cache) and `addons/` (third-party plugin code).
- Reading `.tscn` scene files is fine, but make scene changes in the Godot editor, not by editing the text.
- Godot 4.7, GDScript, 2D only.
- **Claude maintains this guide** (and the other .md files). I read it as my reference but don't edit it myself, so keep it up to date: the Status checklist, Notes and gotchas, and Decisions, whenever something changes.
