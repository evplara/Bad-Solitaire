# Bad-Solitaire
1. Model-View-Controller (MVC) Pattern (Lite)
How it's used: The program separates logic into:

Model: Tables like deck, tableau, suitPiles, and drawnCards represent the game state.

View: The love.draw function handles rendering cards based on the current state.

Controller: love.mousepressed, love.mousereleased, and love.mousemoved handle user interaction and modify the game state.

Why: Separating game state, rendering, and input makes the game easier to debug, extend, and understand.

2. State Pattern
How it's used: Cards have a faceUp boolean that determines whether they are face-up or face-down, influencing both rendering and logic.

Why: Encapsulating the card's "state" helps enforce Solitaire rules (e.g., only face-up cards can be moved).

3. Command Pattern (Ad-Hoc)
How it's used: When dragging a card or stack, the action is "deferred" until mousereleased, where the actual move is executed or cancelled.

Why: This helps validate and conditionally commit actions only if they follow Solitaire’s rules — useful for undo systems later too.

4. Factory Pattern (Manual Initialization)
How it's used: Cards are created in a nested loop using table.insert(deck, {suit=suit, rank=rank, faceUp=false}), acting as a basic card factory.

Why: Automating card generation keeps the code concise and avoids manually writing 52 card definitions.

5. Observer Pattern (Conceptual)
How it's used: Although not implemented formally, the game loop (love.update and love.draw) reacts to changes in card state and tableau automatically.

Why: LÖVE2D inherently uses a reactive loop model — this fits naturally with observer-style updates when game state changes.

6. Data-Driven Design
How it's used: Suits, ranks, and card images are loaded from data tables, allowing the game logic and visuals to scale easily or be themed.

Why: Makes the system extensible — you could add jokers or custom decks with minimal code changes.


Postmortem:
Debugging was difficult for me. I use a lot of print statements for debugging and I would often print the wrong data e.g. printing where the data is stored rather than the actual data. This made it difficult to fix problems such as cards disappearing when clicking a stack or ace not being able to be moved to the suit pile. I also wanted to add so much more but learning of the part 2 project, that will have to wait till later.

Assets:
All card designs by Byron Knoll from https://byronknoll.blogspot.com/2011/03/vector-playing-cards.html 
Back of card image by user jeffshee from https://opengameart.org/content/colorful-poker-card-back
