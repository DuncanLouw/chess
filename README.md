# Chess (working title)

Chess made in Godot, built so that rule variants are easy to add: atomic ("nuke") chess, 4-player chess, games with fewer pieces, custom starting positions and more.

> **Status:** early work in progress. The board and pieces are in. Piece movement and the rules come next.

## Planned variants

- Standard chess (first)
- Fewer pieces and custom starting positions
- King of the Hill
- Atomic ("nuke") chess
- 4-player chess

## Running it

1. Install [Godot 4.7](https://godotengine.org/).
2. In Godot's Project Manager, choose **Import** and select `project.godot` from this folder.
3. Press **F5** to run.

The vector art plugin is already included in `addons/`, so nothing else needs installing.

## How it's built

Each variant is a data file in `variants/` that holds the board layout and the players with their colours. The rules are small functions that a variant can override, so a new variant is mostly data plus a few changed rules. The full design notes are in [project_guide.md](project_guide.md).

The pieces are vector art, drawn in Inkscape and imported with the Scalable Vector Shapes 2D plugin, so they stay sharp at any size. One drawing per piece type is used for every side, and each side's colours are applied in the game.

## Credits

- Made with [Godot Engine](https://godotengine.org/) (MIT license).
- [Scalable Vector Shapes 2D](https://github.com/Teaching-myself-Godot/ez-curved-lines-2d) by René van der Ark, Mark Hedberg and contributors (MIT license), included in `addons/curved_lines_2d/`.
- Piece art drawn by me in Inkscape, based on the chess piece diagrams by Cburnett on Wikimedia Commons (as used in Wikipedia's [Chess piece](https://en.wikipedia.org/wiki/Chess_piece) article), under the BSD license. See [CREDITS.md](CREDITS.md).

## License

My code and art are under the [Prosperity Public License 3.0.0](LICENSE.md):

- **Free for noncommercial use:** personal projects, hobbies, study, and noncommercial organisations such as charities and schools.
- **Commercial use:** a free 30-day trial. After that, a commercial licence is needed.

**Also allowed, no need to ask:**

- Any kind of teaching or education, including at schools that charge fees and in paid courses.
- Showing or covering the project in videos or streams that earn money, such as on YouTube.

**Contact me for a commercial licence:** duncan.louw4@gmail.com

The plugin in `addons/` keeps its own MIT license, and the original piece designs remain Cburnett's under his licenses (see [CREDITS.md](CREDITS.md)).
