# Pokémon Route Game

A small Python game where the player chooses a starter Pokémon and then moves through a 5x5 route filled with wild Pokémon. The project combines a Tkinter graphical interface, Prolog rules, Pokémon type effectiveness, and a fuzzy-logic system to decide the safest next battle.

## Preview

### Starter selection

![Starter selection screen](docs/starter-selection.png)

### Route simulation

![Route simulation screen](docs/game-board.png)

## How the project works

The game starts by asking the player to choose one of three starter Pokémon: Bulbasaur, Charmander, or Squirtle. After the starter is selected, the route is loaded from Prolog and displayed in a Tkinter window.

Each turn, the game checks the possible adjacent rooms from the current position. A room is considered valid if it is inside the 5x5 map and contains a Pokémon. For every possible move, the game calculates:

1. The level difference between the player's Pokémon and the wild Pokémon.
2. The type effectiveness of the player's Pokémon against the defender.
3. A fuzzy probability of winning the battle.

The game then chooses the adjacent room with the highest probability of victory. If the player wins, the starter moves to that room and may level up. If the player loses, the game ends. The goal is to visit all Pokémon rooms without losing.

## Main technologies used

- **Python**: main game logic and project structure.
- **Tkinter**: graphical user interface.
- **Pillow**: image loading and resizing.
- **SWI-Prolog + PySWIP**: logic rules, route data, Pokémon facts, and type-effectiveness queries.
- **NumPy + scikit-fuzzy**: fuzzy-logic probability calculation.

## Project structure

```text
pokemon_route_students/
├── main.py
├── requirements.txt
├── game/
│   ├── pokemon_game.py
│   └── pokemon_fuzzy.py
├── gui/
│   ├── starter_gui.py
│   └── pokemon_gui.py
├── images/
│   ├── bulbasaur.png
│   ├── charmander.png
│   ├── squirtle.png
│   ├── pidgey.png
│   └── rattata.png
└── prolog/
    ├── pokemon_game.pl
    ├── pokemon_route.pl
    ├── pokemon_list.pl
    └── pokemon_info_attacks.pl
```

## Installation

### 1. Install SWI-Prolog

PySWIP requires SWI-Prolog to be installed on your system.

On macOS:

```bash
brew install swi-prolog
```

On Ubuntu/Debian:

```bash
sudo apt update
sudo apt install swi-prolog
```

On Windows, install SWI-Prolog from the official installer and make sure it is available in your system `PATH`.

### 2. Create a virtual environment

```bash
python -m venv venv
source venv/bin/activate      # macOS/Linux
# venv\Scripts\activate       # Windows
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
pip install pillow
```

> Note: the current code imports `PIL` from Pillow, but `Pillow` is not listed in `requirements.txt`. You can either install it manually or add it to `requirements.txt`.

### 4. Run the game

```bash
python main.py
```

## Game flow

The entry point is `main.py`. It first opens the starter selection window. If the user chooses a starter, the game creates both the GUI and the game engine, then starts the step-by-step simulation.

```python
from game.pokemon_game import PokemonGame
from gui.pokemon_gui import PokemonGUI
from gui.starter_gui import StarterGUI

starter_gui = StarterGUI()
starter = starter_gui.run()

if starter is None:
    return

prolog_file = "prolog/pokemon_game.pl"

gui = PokemonGUI(prolog_file=prolog_file, starter_id=starter)
game = PokemonGame(prolog_file=prolog_file, starter_id=starter)

gui.start_game(game, delay=800)
gui.run()
```

## Important code snippets

### 1. Starter selection GUI

`StarterGUI` creates a small window with three buttons. Each button stores the selected Pokémon id and closes the window.

```python
starters = {
    1: "bulbasaur",
    4: "charmander",
    7: "squirtle"
}

for pid, name in starters.items():
    img_path = os.path.join(image_folder, f"{name}.png")
    img = Image.open(img_path).resize((96, 96))
    img = ImageTk.PhotoImage(img)

    btn = tk.Button(
        frame,
        image=img,
        command=lambda p=pid: self.choose(p)
    )
    btn.pack(side="left", padx=20)
```

This is an important part of the project because it shows how to connect GUI events to game data.

### 2. Route definition in Prolog

The map is stored as a 5x5 Prolog list. Each cell contains a pair `(PokemonId, Level)`. The starting cell is `(0,0)`.

```prolog
route([[(0,0),(19,2),(16,7),(16,7),(16,6)],
       [(16,2),(16,2),(16,4),(19,3),(16,3)],
       [(16,3),(16,2),(16,3),(16,2),(16,5)],
       [(16,2),(19,3),(19,5),(16,3),(16,7)],
       [(19,2),(19,2),(19,3),(19,4),(16,7)]]).
```

To create a different route, edit this file and keep the map size as 5x5 unless you also update the hardcoded size checks.

### 3. Getting valid adjacent rooms with Prolog

The Prolog code calculates the possible positions around the player and removes invalid positions outside the board.

```prolog
next_rooms(X,Y,Rooms) :-
    route(Route),
    next_positions(X, Y, Positions),
    build_rooms(Route, Positions, Rooms).

next_positions(X, Y, Positions) :-
    XUp is X - 1,
    XDown is X + 1,
    YLeft is Y - 1,
    YRight is Y + 1,
    valid_positions([[XUp, Y], [XDown, Y], [X, YLeft], [X, YRight]], Positions).

validate(X, Y) :-
    X >= 0,
    X < 5,
    Y >= 0,
    Y < 5.
```

This is one of the main learning points: Prolog is used to represent facts and rules, while Python asks Prolog questions using PySWIP.

### 4. Querying Prolog from Python

The game engine loads Prolog files and asks for information such as the player's starting position or the Pokémon data.

```python
self.prolog = Prolog()
self.prolog.consult(prolog_file)

result = list(self.prolog.query("player_starts(X,Y)"))
self.pos = (result[0]['X'], result[0]['Y'])

pokemon_info = list(self.prolog.query(
    f"pokemon({self.pokemon_starter},Name,Types)"
))[0]
```

This connects Python's object-oriented logic with Prolog's knowledge base.

### 5. Type effectiveness calculation

The method `total_attack` checks the attack multiplier for each attacker type against the defender's types. For Pokémon with multiple types, the multipliers are combined.

```python
def total_attack(self, attacker_types, defender_types):
    prolog = Prolog()
    prolog.consult("prolog/pokemon_info_attacks.pl")

    best = 0

    for attacker in attacker_types:
        total = 1
        for defender in defender_types:
            result = list(prolog.query(f"attack({attacker},{defender},R)"))
            for res in result:
                total *= float(res["R"])
        if total > best:
            best = total

    return best
```

This part teaches how rule-based knowledge can be separated from the Python code. Instead of hardcoding all type matchups in Python, they are stored as Prolog facts.

### 6. Evaluating the best next room

The game evaluates each unvisited adjacent room and chooses the one with the highest fuzzy probability.

```python
def evaluate_next_rooms(self, pokemon_level, pos):
    list_next_rooms = list(self.prolog.query(f"next_rooms({pos[0]},{pos[1]},L)"))

    best_room = None
    best_prob = -1

    for room in list_next_rooms[0]['L']:
        if (room[3], room[4]) not in self.visited_rooms:
            level_input = pokemon_level - room[2]
            effect_input = self.total_attack(self.pokemon_starter_types, room[5])

            prob_of_win = calculate_prob(level_input, effect_input)

            if prob_of_win > best_prob:
                best_prob = prob_of_win
                best_room = room

    return best_room, best_prob
```

The strategy is greedy: at each turn, it picks the best immediate option instead of planning the entire route in advance.

### 7. Fuzzy-logic probability system

The fuzzy system receives two inputs:

- `level`: the player's level minus the defender's level.
- `effect`: the type-effectiveness multiplier.

It returns a probability between `0` and `1`.

```python
level = ctrl.Antecedent(np.arange(-7, 7, 1), 'level')
effect = ctrl.Antecedent(np.arange(0, 4.5, 0.5), 'effect')
prob = ctrl.Consequent(np.arange(0, 1.1, 0.1), 'prob')

rule1 = ctrl.Rule(level['low'] & effect['weak'], prob['low'])
rule5 = ctrl.Rule(level['equal'] & effect['normal'], prob['medium'])
rule9 = ctrl.Rule(level['high'] & effect['strong'], prob['high'])

prob_output = fuzz.defuzz(prob.universe, aggregated, "centroid")
return prob_output
```

The fuzzy rules model intuitive decisions such as:

- Low level and weak attack means low chance of winning.
- Equal level and normal attack means medium chance.
- High level and strong attack means high chance.

### 8. Moving Pokémon on the canvas

The GUI stores each image by board position. When the player moves, it deletes the target Pokémon image and animates the starter image into the new position.

```python
def move_pokemon(self, old_pos, new_pos, steps=16):
    if new_pos in self.map_images:
        self.canvas.delete(self.map_images[new_pos])
        del self.map_images[new_pos]

    img_id = self.map_images[old_pos]
    dx = (new_pos[1]-old_pos[1]) * TILE_SIZE
    dy = (new_pos[0]-old_pos[0]) * TILE_SIZE
    step_x = dx / steps
    step_y = dy / steps

    def animate(step=0):
        if step < steps:
            self.canvas.move(img_id, step_x, step_y)
            self.root.after(20, animate, step+1)
        else:
            self.map_images[new_pos] = img_id
            del self.map_images[old_pos]

    animate()
```

This demonstrates event-based animation in Tkinter using `root.after()` instead of blocking loops.

## Main points to learn from this project

1. **How to separate responsibilities**
   - `main.py` starts the application.
   - `StarterGUI` handles starter selection.
   - `PokemonGUI` handles drawing and animation.
   - `PokemonGame` handles game rules.
   - Prolog files store facts and rule-based logic.

2. **How to connect Python and Prolog**
   - Python uses PySWIP to consult `.pl` files and run Prolog queries.
   - Prolog is useful for facts such as Pokémon data, type effectiveness, and valid board positions.

3. **How fuzzy logic can model uncertainty**
   - Battles are not decided only by fixed rules.
   - The game estimates a probability based on level difference and attack effectiveness.
   - The final result still includes randomness, making each run different.

4. **How to build a simple GUI game loop**
   - Tkinter windows are updated using `root.after()`.
   - The GUI repeatedly asks the game engine for the next step.
   - Images are moved smoothly across a canvas.

5. **How to work with external assets**
   - Pokémon images are loaded from the `images/` folder.
   - Image filenames must match the Pokémon names used by Prolog.

## How to customize the project

### Change the map

Edit `prolog/pokemon_route.pl` and change the Pokémon ids or levels.

```prolog
% each pair is (IdPokemon, Level)
route([[(0,0),(19,2),(16,7),(16,7),(16,6)],
       ...
]).
```

### Add a new Pokémon to the route

Before using a new Pokémon id in the route, make sure:

1. The Pokémon exists in `prolog/pokemon_list.pl`.
2. Its image exists in the `images/` folder.
3. The image filename matches the Prolog name.
4. Its types exist in `prolog/pokemon_info_attacks.pl`.

For example, if Prolog contains:

```prolog
pokemon(25, pikachu, [electric]).
```

Then the image should be:

```text
images/pikachu.png
```

### Change the starter Pokémon

Edit the `starters` dictionary in `gui/starter_gui.py`.

```python
starters = {
    1: "bulbasaur",
    4: "charmander",
    7: "squirtle"
}
```

## Current limitations

- The board size is hardcoded as 5x5 in some places.
- The current route mainly uses Pidgey and Rattata.
- Not every Pokémon in `pokemon_list.pl` has a corresponding image in the `images/` folder.
- Some Pokémon types listed in `pokemon_list.pl`, such as `fairy` or `steel`, are not fully represented in the attack-effectiveness file.
- The strategy chooses the best immediate move, but it does not calculate a complete optimal path.
- The `venv/`, `__pycache__/`, `.DS_Store`, and other generated files should not be committed to GitHub.

## Recommended `.gitignore`

```gitignore
venv/
__pycache__/
*.pyc
.DS_Store
.env
```

## Authors

- Luis Pacheco
- Ruben Fonseca
