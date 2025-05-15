# Bad-Solitaire
Patterns Used:
State
We use a gameState variable ("playing" vs "won") to alter behavior in love.draw and input handlers, effectively implementing a finite state machine that changes the game’s UI and input logic when the player wins. 

Why: Encapsulating the card's "state" helps enforce Solitaire rules (e.g., only face-up cards can be moved).

Command
Each player move (drawing cards, sliding stacks, placing onto piles) is wrapped as a move‐object in moveHistory, with execute‑like logic on drop and an undo method in undoMove. This cleanly encapsulates actions and supports undo/redo of moves.

Why: This helps validate and conditionally commit actions only if they follow Solitaire’s rules useful for undo systems later too.

Factory 
How it's used: Cards are created in a nested loop using table.insert(deck, {suit=suit, rank=rank, faceUp=false}), acting as a basic card factory.

Why: Automating card generation keeps the code concise and avoids manually writing 52 card definitions.

Flyweight
All 52 card textures are loaded once into a shared cardImages cache and reused for every card instance. This avoids duplicating large texture memory per card and mirrors the Flyweight intent of sharing intrinsic state.

Why: Avoid loading or storing 52 separate textures for every single card instance in play—every “3 of Clubs” on the table references the same cardImages["clubs3"] object. That slashes both GPU memory usage and load times, which is exactly the efficiency goal of Flyweight. Although not relevant for a 4MB game, it is useful to not have to type out every card in my code. 

Observer (Conceptual)
How it's used: Although not implemented formally, the game loop (love.update and love.draw) reacts to changes in card state and tableau automatically.

Why: LÖVE2D inherently uses a reactive loop model — this fits naturally with observer-style updates when game state changes.

Data-Driven Design
How it's used: Suits, ranks, and card images are loaded from data tables, allowing the game logic and visuals to scale easily or be themed.

Why: Makes the system extensible — you could add jokers or custom decks with minimal code changes.


Postmortem:
Debugging was difficult for me. I use a lot of print statements for debugging and I would often print the wrong data e.g. printing where the data is stored rather than the actual data. This made it difficult to fix problems such as cards disappearing when clicking a stack or ace not being able to be moved to the suit pile. I also wanted to add so much more but learning of the part 2 project, that will have to wait till later.

Postmortem, but Better:
I had lots of strange bugs appear. One that I did not notice until a while after playtesting was clicking/dragging a card stack would flip the entire stack in reverse?? I had this code
for k=j, #pile do
  local c = table.remove(pile)    -- always pops the *last* element
  table.insert(draggingStack, c)
end
which would pop the last card and loop until it got to the bottom, creating a reversed stack. Refactoring my code was useful as there were many, frankly, game-breaking bugs in my first version. Such as cards disappearing and not being able to move stacks, which appeared a lot whenever I would try and fix something else. For example, when implementing the Flyweight pattern to refactor my code, it would crash. So, after fixing the crash, the card stacks would not move anymore. Very frustrating, but I got it to work and created useful, reusable code.

Assets:
All card designs by Byron Knoll from https://byronknoll.blogspot.com/2011/03/vector-playing-cards.html 
Back of card image by user jeffshee from https://opengameart.org/content/colorful-poker-card-back
