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
│   ├── config/          ← fixed names used across the code (piece_names.gd)
│   └── rules/           ← rule scripts (standard chess + one per variant that changes rules)
├── sprites/pieces/      ← piece art the game uses (.svg), exported from art_source
├── art_source/pieces/   ← Inkscape working files (has .gdignore, so Godot ignores it)
├── variants/            ← one .tres file per chess variant (standard.tres; test_*.tres for testing)
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
- Colours: **white `#ffffff`** becomes the side's fill colour, **black `#000000`** becomes the side's outline colour, and **greys** become a mix of the two. One file works for every side. Details like the bishop's cross can simply be **black filled shapes**; no outline tricks needed.
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
| Use Line2D for Strokes                        | **on**      | outlines become `Line2D` nodes, which keep their width when scaled. (Colouring no longer depends on this: it goes by each shape's colour.) |
| Flag on antialiased for Polygon2D and Line2D  | your choice | smooth edges, see [Antialiasing](#antialiasing-smooth-edges) below                                                                                                             |

- The SyncedSVGRoot position of (-50, -50) moves the page's centre onto the scene's origin, so a piece placed at a square's centre sits in the middle of it.
- **Piece size on the board:** `board.gd` has `@export var piece_scale := 0.9`, and each placed piece gets `scale = Vector2.ONE * piece_scale`. Because the piece scene's origin is its centre, scaling keeps it centred on the square. With the outline sticking out ~2 px, a piece is ~104 px wide at scale 1, so 0.9 leaves a ~3 px gap on each side of a 100 px square (0.85 leaves ~6 px). Later this can become a player setting: change `piece_scale` and update the scale of every node in `Pieces`.
- A quick way to make a new piece scene: duplicate an existing one, rename its root node, select SyncedSVGRoot and change **Svg Resource Path** to the new SVG.

### Changing art later

- Edit and save the .svg in Inkscape, then open that piece's scene in Godot and it reimports. If you only see a warning, select SyncedSVGRoot and press **Reimport** in the Inspector.
- **Never edit the imported shapes inside Godot.** The next reimport replaces them.
- SyncedSVGRoot remembers the import settings. Changing one of them in its Inspector (for example **Is Aa** or **Is Svs**) reimports the piece with the new setting.

### Colours

Each side has a fill colour and an outline colour (set in the variant). `piece.gd` recolours every `Polygon2D` and `Line2D` by its **original brightness** in the SVG: white (1) → fill colour, black (0) → outline colour, grey → a mix (`outline.lerp(fill, brightness)`). The original brightness is stored on each node with `set_meta`, so recolouring the same piece again still works.

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
| **GameState** | a plain data object           | what's on each square, whose turn it is, every piece by id, the move history | draw anything, or decide what's legal |
| **Rules**     | a script in `scripts/rules/`  | how pieces move, what's legal, what a move does, when the game ends          | touch nodes or sprites                |
| **View**      | Board, piece scenes, input    | drawing, clicks, animation                                                   | decide rules (it asks Rules)          |

`main.gd` connects them. It loads a variant, builds the GameState from the variant's layout and tells the view to show it.

**Three dictionaries, three jobs:**
- `GameState.squares` (`Vector2i` → `PieceData`) is the game itself. The rules read and change it, and can try a move and undo it (for check detection) without anything changing on screen.
- `Board.piece_nodes` (`PieceData` → `Piece` node) only tracks which node shows which piece. It never decides anything. The key is the piece's **PieceData object**: `apply_move` moves that same object to its new square, so the board can find its node wherever the piece goes.
- `GameState.pieces_by_id` (`int` → `PieceData`) holds every piece made in the game, captured ones included. Undo uses it to find the original object for a recorded copy, so the board keeps the same node.

**How the screen follows the state:**
- **After a move: `Board.update_pieces(state, variant)`.** It goes through the state: a piece that already has a node gets its node moved to its square, a piece without a node gets a new one (e.g. a promoted pawn), and nodes whose piece is no longer on the board (captured) are deleted. It never needs to know *what* happened, so castling, en passant, promotion, atomic explosions and future variants need no extra screen code, and the screen can't drift from the game. A normal move creates no nodes at all.
- **At the start, and with the Refresh button: `Board.show_state`** deletes every node and calls `update_pieces`, which then creates them all (~125 ms for a full board). If Refresh ever changes what you see, `update_pieces` has a bug.
- **Later, for animations:** in `update_pieces`, slide the node to its new position (a Tween) instead of setting the position directly. Only `board.gd` changes.

**Move history (decided 17 Nov, my design):** `GameState.history` is the list of every Move played, in order, and each played Move also **records what actually changed**. That gives:
- **instant stepping backwards** (undo, rewatching in reverse): put back what the record says, no replaying from the start
- **a timeline of captures** without simulating anything (does the move's record contain removed pieces?)
- **a self-contained history**: old games still show exactly what happened even if a variant's rules change or the variant is deleted
- **cheap "what if" testing for check detection:** apply a move, check the king, undo it, with no copy of the board

How the record is made (my idea: **compare before and after**), so it's correct for every rule (castling, en passant, promotion, explosions, future variants) with no extra code per rule:
- Just before a move is **played**, take a snapshot of the state (every square, every piece's fields, whose turn). Play the move. Compare: every square whose piece is different, or whose piece has different field values (like `has_moved`), goes into the record with **copies** of the piece before and after, plus the turn before and after.
- **Copies, not references.** A reference to a PieceData object would show its *current* values, so a later move changing `has_moved` would silently change old records too. Copies freeze the moment.
- PieceData gets a `copy()` that copies **every** field automatically (Godot can list an object's variables), so adding a field to PieceData later needs no change to the recorder.
- It also catches changes that don't touch `squares` at all (a rule that flips `has_moved`, or a variant where a captured piece switches sides), which a "log every square change" function would miss.
- **Undo** writes the "before" values back. Write them *into the original PieceData objects* rather than putting the copies on the board, so the board's identity-matching still finds the existing nodes (no new nodes, stays ~0.1 ms).
- Only played moves get a record. Check detection can use the same snapshot/compare/undo to test moves: about 30 to 40 test moves per click, each well under a millisecond.
- **Pieces get an `id`** (unique per game: given by `GameState.create_piece`, which `load_layout` uses, and new pieces like a promoted queen must be made with it too). Copies keep the id, so a record can tell "knight 7 moved from b1 to c3" apart from "a pawn vanished and a queen appeared", undo can find the original object to write the values back into, and saved files can name pieces.
- **Copy each piece, not just the dictionary.** `squares.duplicate()`, even `duplicate(true)`, copies the dictionary but *not* the objects inside it: both dictionaries would point to the same PieceData objects.
- **The snapshot covers the whole GameState except the history:** squares, turn, and anything added later that isn't on a square (e.g. castling rights, if those ever get stored there).
- **Comparing:** a square goes into the record if its piece is a different one (different id, or null on one side) or the same one with any field changed. PieceData gets an `equals()` that checks every field automatically, like `copy()`.
- **Undo and redo:** keep a position in the history instead of deleting records. Back = write the "before" values (newest move first; inside one move each square appears only once, so the order there doesn't matter), forward = write the "after" values. A new move played after stepping back drops the records after that position (like undo in any editor).
- **Rewatching never runs the rules:** it only writes the recorded values. If the file says a pawn reached the last row and stayed a pawn, that's what is shown.
- Replaying from the start stays possible (it's fast: only `apply_move` runs, no move checking), but it isn't needed for undo.

**Move history in the code (built 17 Nov):**
- **`state.play_move(rules, move)` plays a move.** It drops any undone moves, takes a snapshot (`take_snapshot()`, a `GameState.Snapshot` with copies of every piece and the turn), lets `rules.apply_move` change the state, then fills in the Move's record: `move.changes` (an `Array[SquareChange]`, each with `square`, `before` and `after` copies; `null` = empty) and `move.turn_before` / `move.turn_after`.
- **Always play moves through `play_move`.** Calling `rules.apply_move` directly changes the board without a record, so that move can't be undone.
- **`state.undo()` / `state.redo()`** write a move's `before` / `after` copies back with `_put_piece`, which finds the original object in `pieces_by_id` and copies the values into it (`copy_from`). `can_undo()` / `can_redo()` say whether there's anything to go back or forward to (later: grey out the buttons).
- **`state.create_piece(type, side)`** makes every piece and gives it the next id. A piece made with `PieceData.new()` during a game has no id, and undo reports "No piece with id -1".
- **`PieceData.copy()`, `copy_from()` and `equals()`** go through `_field_names()`, which asks Godot for every `var` the script declares (`get_property_list()`, keeping the ones marked `PROPERTY_USAGE_SCRIPT_VARIABLE`). A new variable in PieceData is copied and compared without changing them.
- If a move ever adds or removes board squares (not just pieces), `_find_changes` reports an error: the record only covers what's *on* the squares.

**Saving games to disk (later, after menus). Ideas from 17 Nov:**
- **In memory and on disk are separate choices.** In memory the history always keeps the change records (undo, rewatching, check detection need them). The file format is decided separately.
- **One file format: moves + their change records.** Size isn't a real concern: roughly 50 to 100 bytes per move as text, so a long 200-move game is ~10 to 20 KB, and a thousand games ~20 MB (compressible with `FileAccess.open_compressed`). A player-selectable "small vs full" format would double the save/load code and testing for a difference nobody would notice. A compact "moves only" export (like chess notation) can be added later for sharing, if wanted.
- **What the file needs besides the moves:**
  - a **format version** number, so files from older versions of the game can still be read after the format changes
  - a **copy of the variant**, so a game can be rewatched even after the variant is changed or deleted. ("Atomic v1" and "atomic v2" count as different variants.) With change records, rewatching doesn't need the rules, but it still needs the layout **and** the sides (letters and colours) and piece names, or it can't draw the pieces. Simplest: store the variant inside each game file (~1.3 KB of text next to ~10 to 20 KB of moves). The "one copy per folder of games" idea saves a little space, but it needs a version of the variant for every change made to it, so it's only worth it if storage ever becomes a problem.
  - a small **id per piece** (given when the layout is loaded): in memory, PieceData objects are matched by identity, but a file can only store plain data, so ids say "this is the same knight as on move 5"
  - player choices aren't needed in the file: rewatching writes the recorded values, it doesn't replay choices. (The Move still carries the choice while it's being played, so `apply_move` knows what to create; undoing and playing it again by tapping simply asks again.)
  - **storage layout (decide later):** one stored file holding all games (avoids Windows' 4 KB minimum per file), with **export** writing a single game plus its variant copy. A single big file needs careful saving (write a new file, then swap it in), so one failed save can't lose every game.
  - **Rules:** rewatching doesn't need them (it writes recorded values). Continuing an old unfinished game does, and then it uses the rules installed in the game. **Never load script code from a game file:** a shared file could contain anything, and running it would be a security risk. Store the rules' *name and version* for information, not the code.
- **Future uses of the history:** the standard draw rules (threefold repetition, the 50-move rule) look back through it.

**Data objects in Godot:** a `Node` lives in the scene (draws, gets input). A `Resource` is data saved as a file and edited in the Inspector (`ChessVariant`, `Side`). A `RefCounted` is plain data that only exists while the game runs and is deleted automatically when nothing uses it (`GameState`, `PieceData`, `Move`, `SquareChange`).

**A click from start to finish:**

1. The **Board** turns the click or tap into a square (`position_to_square`) and sends its `square_clicked` signal. It decides nothing itself.
2. **`main.gd`** receives it (`_on_square_clicked`) and does one of three things:
   - a move of the selected piece goes to that square: `state.play_move(rules, move)` (the rules play it, the state records it), deselect, then `board.update_pieces(...)`
   - it's one of the current player's pieces: `rules.get_legal_moves(state, square)`, then `board.show_moves(...)` (selected square tinted, dots on empty targets, tinted squares for captures)
   - anything else: deselect (`board.clear_moves()`)
3. Later: after each move, `rules.get_winner(state)` checks whether the game is over.

The **Undo** and **Redo** buttons do the same as a move, the other way round: `state.undo()` / `state.redo()`, deselect, `board.update_pieces(...)`.

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
| `apply_move(state, move)`        | changes the state (via `play_move`)    | move, capture, castling, en passant, promotion |
| `on_capture(state, move)`        | extra effects of a capture             | nothing                                        |
| `get_next_side(state)`           | whose turn is next                     | the other player                               |
| `get_winner(state)`              | is the game over, and who won?         | checkmate wins, stalemate is a draw            |

- **Rules never store the game.** Every function receives the state as a parameter. That lets check detection try a move and undo it (with the change records) without the real game or the screen changing.
- Rules extend `Resource`, so they can have **settings** (`@export` variables) that each variant sets in the Inspector, for example `@export var explosion_radius := 1`.
- **Each variant picks its rules in the Inspector:** ChessVariant → Rules → *New Rules* (standard chess). A variant with changed rules picks its own class instead, e.g. *New AtomicRules*. `main.gd` won't start a game whose variant has no Rules set.
- **Movement helpers** in `rules.gd`: `_slide_moves(state, from, directions)` (rook, bishop, queen, pawn forward: keep going until the edge, a piece, or an optional `max_distance`) and `_step_moves(state, from, steps)` (king, knight, pawn capture: one step or jump each). Both take an optional `capture_rule` (`CaptureRule.MOVE_OR_CAPTURE` by default, `MOVE_ONLY`, `CAPTURE_ONLY`), and both ask `_can_land(piece, other, capture_rule)` whether a piece may end on a square, so the capture rules live in one place. Direction lists are constants: `STRAIGHT`, `DIAGONAL`, `ALL_DIRECTIONS`, `KNIGHT_JUMPS`, `PAWN_MOVES`, `PAWN_CAPTURE`. **Every pattern is written from white's point of view (forward = up)**, and both helpers turn it to face the piece's side with `align_to_forward(vec, forward)`, where `forward` is `state.sides[piece.side].forward`. So one pattern works for every side, including sides moving left or right.
- A **Move** (`scripts/move.gd`, RefCounted) holds `from` and `to`, later the extras for special moves, and once played its change record (`changes`, `turn_before`, `turn_after`; see Move history).
- `GameState.side_count` (from the variant) is used for whose turn is next: `(turn + 1) % side_count`.

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
| Double-move knight (idea): a knight may jump again from where it landed | Override `get_piece_moves` for the knight, using a chained-jump helper with `max_jumps = 2`. |
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
  2. **Done:** moves for the rook, bishop, queen and king (ignoring check), tap/click to select, dots and capture tints, tap to move. Rules set in `standard.tres`; test variants `test_no_pawns.tres` and `test_only_knight.tres`. Piece type names are constants in `scripts/config/piece_names.gd` (`PieceNames.ROOK`, ...).
     - **Lag between moves: fixed (16 Nov).** `Board.update_pieces` (sync by PieceData) takes ~0.1 to 0.2 ms per move instead of ~125 ms. Also added: `GameState.history` and a Refresh button (with its own vector icon). `history.clear()` added to `load_layout`; timing prints removed.
  3. **Knight: done** (`KNIGHT_JUMPS` + `_step_moves`). **Pawn: forward move, double first move and diagonal capture done for every side** (17 Nov: Claude wrote `CaptureRule` and `max_distance` on request; 19 Nov: the direction for each side, my `align_to_forward`). Still to do: en passant and promotion. Notes from the 17 Nov review:
     - **Done (19 Nov):** "Forward" depends on the side (`Side.forward`), so `PAWN_MOVES = [Vector2i.UP]` only works for white. The rules only get the state, so the state needs the sides (e.g. `GameState.sides`, set in `load_layout`). For the diagonals: forward plus one step to each side, and for a sideways-moving pawn (4-player) "each side" is different, so work it out from `forward`.
     - **Done:** a `can_capture` bool wasn't enough (pawns need three cases: move or capture / move only / capture only), so `rules.gd` has `enum CaptureRule { MOVE_OR_CAPTURE, MOVE_ONLY, CAPTURE_ONLY }` as a default parameter, and existing calls didn't change. The shared check `_can_land` is my idea from the old draft comment: one function that both helpers call.
     - **Done:** the double first move is a slide with a maximum distance (blocked by pieces, no capture): `_slide_moves(..., CaptureRule.MOVE_ONLY, max_steps)`. `_numbered_moves_can_capture` was removed. **Chained jumps** (my idea: a knight jumps again *from where it landed*, e.g. up-left then down-left = two squares left) are different from a slide: a helper like `_chained_step_moves(..., max_jumps)` in the base Rules class would be a toolbox function for variants. **Not written yet:** it comes with the double-jump knight variant, because nothing in standard chess calls it, so F5 couldn't test it. Things to handle: never land on your own pieces, a capture ends the chain (could become a CaptureRule option later), and one square reachable by two paths is still one Move (check for duplicates). The starting square is blocked by the own-piece check automatically, as long as the search only *reads* the state and never moves the knight while looking.
     - En passant: the captured pawn isn't on the square you move to, so `apply_move` needs to know which square to clear. The Move generator can say which square the captured pawn is on; the change record (see Move history) then logs the removal like any other change.
     - **Notes from the 19 Nov review (direction), all fixed the same day:**
       - **The approach (mine): every move pattern is written from white's point of view (forward = up) and turned to face the piece's side** with `align_to_forward(vec, forward)`, inside `_slide_moves` and `_step_moves`. It turns every piece's pattern, not just the pawn's: symmetric pieces (rook, knight, ...) come out the same, and it also works for 4-player and for future one-sided fairy pieces.
       - **The formula's signs are right** (a 90° rotation: `new_x = -x*fy - y*fx`, `new_y = x*fx - y*fy`), but the code changed `x` first and then used the *new* `x` for `y`. Black still looked right (its `fx` is 0), so the bug would only have shown with a side moving left or right. Fix: compute both into new variables, then return them.
       - **In `_slide_moves`, `target += direction` must use the turned direction too**, or every step after the first goes the old way (a black pawn's double step went down one and then back up onto itself). Turn the direction once at the top of the loop and use it in both places.
       - **Where the forward comes from:** the rules only get the state, so the state keeps the sides: `var sides: Array[Side] = []` in `game_state.gd`, `sides = variant.sides` in `load_layout`, then `state.sides[piece.side].forward` in the helpers.
       - Only the four straight directions work as a forward. A diagonal forward would stretch the patterns (a knight jump would land on the wrong square).
       - **Testing a function with known answers:** call it once in `_ready()` with inputs whose answer you already know and print both, e.g. `print(rules.align_to_forward(Vector2i.UP, Vector2i.RIGHT), " should be (1, 0)")`. Quicker than reading prints during a game. Expected: forward `RIGHT` turns `UP` into `(1, 0)` and `(1, -1)` into `(1, 1)`; forward `LEFT` turns `UP` into `(-1, 0)`; forward `DOWN` turns `UP` into `(0, 1)`.
  3b. **Change records + undo/redo: written 17 Nov** (Claude wrote it on request, in its own commit). `PieceData`: `id`, `copy()`, `copy_from()`, `equals()`. New `scripts/square_change.gd`. `Move`: `changes`, `turn_before`, `turn_after` (replacing my draft `deleted` / `all_piece_moves` fields). `GameState`: `pieces_by_id`, `create_piece()`, `play_move()`, `undo()`, `redo()`, `history_position`; `load_layout` also resets `turn`. `apply_move` no longer adds to the history. `main.gd`: plays moves with `state.play_move`, plus `_on_undo_button_pressed` / `_on_redo_button_pressed`.
     - [x] Undo and Redo buttons in `main.tscn`, next to Refresh, with my own arrow icon (`sprites/Other/redo.svg`; the Redo button shows it mirrored with scale x = -1)
     - [x] Tested with F5 (19 Nov): works. What to check after changes to undo: moves and captures (pawns too, for `has_moved`: an undone first move gets its double step back), undo back to the start, redo to the end, then undo and play a *different* move (redo then does nothing). Refresh should never change what's shown.
     - [x] Comments in `rules.gd` updated: the patterns are written from white's point of view, and `align_to_forward` explains the turn
  4. Check: "is this square attacked by side X?" + throw away moves that leave your own king attacked
  5. Castling (my turn to try), promotion, checkmate and stalemate
- [ ] Real art: king, rook, pawn, bishop and knight done. Queen in progress
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
- **`push_error` does not stop the game.** It prints a red message (Debugger → Errors) and the game carries on. `assert(condition, "message")` pauses the game at that line, but only when running from the editor: asserts are skipped completely in exported games. For loading data (layouts, variants), functions return `true`/`false` and the game refuses to start when loading failed. That also works in exported games and later for player-made variants. Report *all* mistakes in one go rather than stopping at the first.
- **GDScript has no named arguments** (no `f(x = 1)` like Python). Get the same safety from types: when every parameter has a different type, a mix-up is a red error before the game runs. Two `int`s side by side can be swapped unnoticed, which is one reason squares are always one `Vector2i`.
- **Folder and file names must match the paths in code exactly** (`scene/` vs `scenes/` broke loading once).
- `Variant` is a built-in Godot type, so it can't be used as a `class_name` (that's why it's `ChessVariant`).
- `"%s" % value` fills `value` into the `%s` blank in the text. Only needed when the text has a blank.
- New piece scenes come out white with a black outline until `set_colors` runs. If every piece looks white, `set_colors` probably never ran.
- `set_meta(name, value)` / `get_meta(name)` attach your own extra values to any node (used to remember each shape's original brightness).
- **Commits:** start with a verb (Add, Fix, Move, Rename, Remove, Update, Draw), keep the summary around 50 characters, one change per commit. Untick files in GitHub Desktop to split art and code into separate commits.
- Code after a `return` never runs (for example a `break` right after `return`).
- A function with a return type (`-> Side`) must return something on every path, so add `return null` at the end when nothing was found.
- Report an error in the function that does the lookup (`find_side`), not in every place that calls it. Callers just check for `null` and stop.
- **Check detection is cheap:** one move function is used for the dots, for check and for checkmate. A few thousand dictionary lookups per click is well under a millisecond, so no clever shortcuts are needed.
- **Pawns are the exception:** they move straight forward but attack diagonally, so "squares a pawn attacks" isn't the same as "squares it can move to".
- **Performance: lag between moves (found 15 Nov; fixed 16 Nov: moves now ~0.1 to 0.2 ms).** `Board.show_state` deletes and recreates **all 32 piece scenes after every move**. Measured with `Time.get_ticks_usec()` around `show_state` (editor runs, roughly ±20% between runs):

  | Pieces as... | All 32 pieces, plugged in | Knights only | All pieces, on battery |
  | --- | --- | --- | --- |
  | Vector, plugin shapes on (Is Svs) | ~125 ms (119 to 135) | ~10 ms | ~270 ms |
  | Same, Is Resource Local off | ~115 ms | | |
  | Same, Is Update Curve At Runtime off | about the same as on | | |
  | Vector, plain polygons (Import as ScalableVectorShape2D off) | ~85 ms | 6.5 ms | |
  | Sprite2D (raster texture) | ~35 ms | 3.5 ms | ~85 ms |

  A frame at 60 fps is 16.7 ms, so anything far above that is a visible hitch.
  - **The plugin's shape nodes cost ~3.5× more than sprites to create**; plain polygons are in between.
  - **Even sprites take ~35 ms** for a full rebuild, so the real problem is rebuilding everything every move.
  - **Fix (done):** `Board.update_pieces` moves the existing node of every piece that moved, deletes captured nodes, and only creates nodes for pieces that are new (e.g. promotion). A normal move then creates no nodes at all.
  - **Decision:** keep the vector pieces. Their cost only shows when the game starts (~125 ms once, fine while loading) and for a new piece (~4 ms).
  - Errors in editor runs are slow too (each is logged with a trace and sent to the editor). If an error repeats on every move, fix it, because it adds time.
  - **Experiments go in uncommitted changes** and are undone with GitHub Desktop → Changes → right-click → Discard changes.
- **Where a real `enum` fits:** options *inside the code* that never come from files or data, like `enum CaptureRule { MOVE_OR_CAPTURE, MOVE_ONLY, CAPTURE_ONLY }` in `rules.gd`. Piece names are text from data, so they're constants instead. An enum can be a parameter type (`capture_rule: CaptureRule`), and a Rules script that extends `Rules` can use `CaptureRule` too.
- **Default parameter values:** `func f(a: int, mode := CaptureRule.MOVE_OR_CAPTURE)` lets callers leave `mode` out, so adding a parameter doesn't mean changing every existing call.
- **`append` vs `append_array`:** `append` adds one item; to add every item of another array, use `append_array`. (Appending an `Array[Move]` into an `Array[Move]` is an error.)
- **Lambdas** (`func(x): ...`) are for passing *behaviour* to something else, like `find_custom`. When you just need a value, compute it first: `var max_steps := 1 if piece.has_moved else 2`.
- **Piece type names are string constants** (`PieceNames.ROOK` in `scripts/config/piece_names.gd`), not a GDScript `enum`. A GDScript `enum` gives names to **numbers**: `enum Piece { ROOK, KNIGHT }` makes ROOK = 0 and KNIGHT = 1, and printing it shows `0`. Piece types have to be text: they name the scene files and come from the variant's data, and a variant can add a new type without touching a central list. Constants still give autocomplete, and a typo (`PieceNames.ROKK`) is an error before the game runs.
- **Why I first made a Dictionary called `Enum`:** in my university capstone project, the database had enums (for example user roles), and its queries needed each enum value's *name as text*. So I made a class holding dictionaries of those names, and carried that habit over here. Database enums are text labels; enums in GDScript (and C#, C++, Java) are named numbers. Same word, different thing. A Dictionary also doesn't check its keys, so a typo only fails while the game runs; named constants are checked before it runs.
- **A `const` can't call a function**, but constants can be built from other constants (`const ALL_DIRECTIONS = STRAIGHT + DIAGONAL`). For a handful of fixed values like the knight's 8 jumps, writing them out is clearer than generating them with loops.
- **The Debugger → Errors tab shows runtime errors and warnings too** (including `push_error`). Empty means none happened.
- **Connecting a signal in the editor:** select the node, open the **Node** tab (next to the Inspector) → Signals, double-click the signal (e.g. a Button's `pressed()`), pick the node whose script should receive it. Godot writes the empty function for you (`_on_refresh_button_pressed`); a green icon next to it in the script editor shows it's connected.
- **Signals:** a node announces that something happened (`signal square_clicked(square: Vector2i)`, then `square_clicked.emit(square)`), and other nodes listen with `board.square_clicked.connect(_on_square_clicked)`. The sender doesn't need to know who listens, which keeps the Board free of game logic.
- **`@onready var board: Board = $Board`** fetches the node once the scene is ready, with a type, so autocomplete works. Better than writing `$Board` everywhere.
- **`queue_redraw()`** asks Godot to call `_draw()` again (for example when the highlights change). Everything drawn in a node's `_draw()` appears *under* its child nodes, so dots and tints are drawn under the pieces.
- **Clicks:** `_unhandled_input(event)` receives input that no UI used. A tap on a touch screen arrives as a left mouse click (Project Settings → Input Devices → Pointing → Emulate Mouse From Touch, on by default). `make_input_local(event)` converts the click position into the node's own coordinates, so it works wherever the board is placed or however the window is scaled.
- **`property = null` lines in a .tscn** appear when a scene is saved while one of its scripts has an error (Godot can't read the defaults). Fix: select the node, click the revert arrow (↺) next to the affected properties in the Inspector, and save the scene.
- **Local vs member variables:** a `var` inside a function is created fresh on every call and thrown away afterwards. Data that must stay (like a dictionary) is a member variable, declared at the top of the script outside any function. (Godot's "singletons" are Autoloads, global nodes; not needed here.)
- A typed `String` can never be `null`. For a dictionary key that might be missing, use `.get(key, "")` and check for `""`, or check `.has(key)` first.
- **Don't overwrite a variable you still need.** `x = ...` followed by `y = ... x ...` uses the *new* `x`. When several new values are worked out from the old ones, put them in new variables first (`new_x`, `new_y`).
- **`Vector2i` has `.x` and `.y`**, which read better than `vec[0]` / `vec[1]`. Give such variables a type (`var x: int = vec.x`, or `:=`) so Godot catches mistakes.
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
- **Android export (set up 18 Nov; tested 19 Nov: installs and runs on my phone):** `export_presets.cfg` is safe to commit: in Godot 4 the keystore passwords are kept in `.godot/export_credentials.cfg`, which is ignored with the rest of `.godot/`. The `android/` build folder is ignored too (`/android/` in `.gitignore`). Exporting for Android also switched on ETC2/ASTC texture import in `project.godot`.
  - **Exported builds never go in the repo** (they're big, and they belong in a Release): `.gitignore` has `*.apk`, `*.aab` and `*.exe`, and the Android preset saves to `android/Chess.apk` (inside the ignored `android/` folder). A Windows export also makes a `.pck` file next to the `.exe` unless "Embed PCK" is ticked, so add `*.pck` to `.gitignore` before the first Windows export into the project folder.
  - **Package name: `com.duncanlouw.chess`** (set 19 Nov). It can't change after publishing on a store, because stores treat a new package name as a different app.
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
- **Error handling: is the mistake in the data or in the code?**
  - *Data* (layouts, variant files, later maybe made by players): `push_error` + return `false`, and that game doesn't start. Only the broken game stops, never the app. Loading reports every mistake in one go.
  - *Code* (things that can't happen if the code is right): `assert(condition, "message")`. It pauses at the line while developing and is removed from exported games.
  - *Later, with menus:* the menu calls the same loading functions. Loading also collects its messages in a list (e.g. "Row 3: unknown piece letter X"); if loading fails, the menu shows them in a popup and stays open. Menus come after standard chess works.
- **After a move, the board syncs its nodes with the state** (`update_pieces`, matching nodes to pieces by their PieceData object) instead of rebuilding everything. `show_state` (full rebuild) is only for the start and the Refresh button. Changed from "rebuild every move" after the performance tests (16 Nov).
- **Move history is a list of played Moves that record what changed** (snapshot before, compare after, copies of the changed pieces), so undo and stepping backwards are instant and old games don't depend on today's rules. Changed on 17 Nov from "replay from the start" (my argument: rewatching backwards, capture timeline, rule changes).
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
