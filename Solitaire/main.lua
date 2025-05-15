-- main.lua
-- Klondike Solitaire in LÖVE2D with drag/drop, undo, reset, win detection

-- Constants
local CARD_SCALE = 0.1
local SPACING_X, SPACING_Y = 80, 30

-- Buttons
local RESET_BTN = {x=650, y=10, w=100, h=30, label='Reset'}
local UNDO_BTN  = {x=650, y=50, w=100, h=30, label='Undo'}

-- Game State
local deck, drawPile, drawnCards, suitPiles, tableau
local draggingStack, moveHistory, gameState
local pileDefs = {}
local mouseX, mouseY = 0,0

-- Resources
local cardImages, cardBackImage
local ranks = {'A','2','3','4','5','6','7','8','9','10','J','Q','K'}
local suits = {'hearts','diamonds','clubs','spades'}

function love.load()
  love.graphics.setBackgroundColor(0, 0.6, 0)
  loadCardResources()
  initPiles()
  initBoard()
end

function loadCardResources()
  cardImages = {}

  -- map our rank symbols to the filename words
  local rankNames = {
    A  = "ace",
    ["2"] = "2", ["3"]="3", ["4"]="4", ["5"]="5",
    ["6"] = "6", ["7"]="7", ["8"]="8", ["9"]="9",
    ["10"]= "10",
    J  = "jack",
    Q  = "queen",
    K  = "king",
  }

  for _, suit in ipairs(suits) do
    for _, rank in ipairs(ranks) do
      local id = suit .. rank               -- e.g. "heartsA"
      local rn = rankNames[rank]            -- e.g. "ace"
      local filename = rn .. "_of_" .. suit .. ".png"
      cardImages[id] = love.graphics.newImage("assets/" .. filename)
    end
  end

  -- your back.png can stay the same
  cardBackImage = love.graphics.newImage("assets/back.png")
end


function initPiles()
  pileDefs = {}
  -- deck + draw
  table.insert(pileDefs, {type='deck',  x=50,               y=50})
  table.insert(pileDefs, {type='draw',  x=50 + SPACING_X,  y=50})
  -- suit piles
  for i=1,4 do
    table.insert(pileDefs, {type='suit', index=i,
      x=50 + (i+1)*SPACING_X, y=50})
  end
  -- tableau piles
  for i=1,7 do
    table.insert(pileDefs, {type='tableau', index=i,
      x=50 + (i-1)*SPACING_X, y=150})
  end
end

function initBoard()
  deck = generateDeck()
  shuffle(deck)
  suitPiles = {{},{},{},{}}
  tableau = {}
  drawPile = {}
  drawnCards = {}
  moveHistory = {}
  draggingStack = nil
  gameState = 'playing'
  -- deal into tableau
  for i=1,7 do
    tableau[i] = {}
    for j=1,i do
      local c = table.remove(deck)
      c.faceUp = (j==i)
      table.insert(tableau[i], c)
    end
  end
  drawPile = deck
  deck = {}
end

function generateDeck()
  local t = {}
  for _, s in ipairs(suits) do
    for _, r in ipairs(ranks) do
      table.insert(t, {id=s..r, suit=s, rank=r, faceUp=false})
    end
  end
  return t
end

function shuffle(t)
  for i = #t, 2, -1 do
    local j = love.math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

function love.draw()
  drawAll()
  if gameState == 'won' then
    love.graphics.printf('You Win!',
      0, love.graphics.getHeight()/2,
      love.graphics.getWidth(), 'center')
  end
end

function drawAll()
  for _, def in ipairs(pileDefs) do
    if def.type == 'deck'     then drawDeck(def)
    elseif def.type == 'draw' then drawDraw(def)
    elseif def.type == 'suit' then drawSuit(def)
    elseif def.type == 'tableau' then drawTableau(def)
    end
  end
  drawDragging()
  drawButton(RESET_BTN)
  drawButton(UNDO_BTN)
end

function drawDeck(def)
  local w = CARD_SCALE * cardBackImage:getWidth()
  local h = CARD_SCALE * cardBackImage:getHeight()
  if #drawPile > 0 then
    drawCardBack(def.x, def.y)
  else
    love.graphics.rectangle('line', def.x, def.y, w, h)
  end
end

function drawDraw(def)
  local w = CARD_SCALE * cardBackImage:getWidth()
  local h = CARD_SCALE * cardBackImage:getHeight()
  if #drawnCards > 0 then
    drawCard(drawnCards[#drawnCards], def.x, def.y)
  else
    love.graphics.rectangle('line', def.x, def.y, w, h)
  end
end

function drawSuit(def)
  local pile = suitPiles[def.index]
  if #pile > 0 then
    drawCard(pile[#pile], def.x, def.y)
  else
    love.graphics.rectangle('line', def.x, def.y,
      CARD_SCALE*cardBackImage:getWidth(),
      CARD_SCALE*cardBackImage:getHeight())
  end
end

function drawTableau(def)
  local pile = tableau[def.index]
  for i, card in ipairs(pile) do
    local x, y = def.x, def.y + (i-1)*SPACING_Y
    if card.faceUp then drawCard(card, x, y)
    else drawCardBack(x, y) end
  end
end

function drawCard(card, x, y)
  love.graphics.draw(cardImages[card.id], x, y, 0,
    CARD_SCALE, CARD_SCALE)
end

function drawCardBack(x, y)
  love.graphics.draw(cardBackImage, x, y, 0,
    CARD_SCALE, CARD_SCALE)
end

function drawDragging()
  if draggingStack then
    for i, card in ipairs(draggingStack) do
      drawCard(card, mouseX, mouseY + (i-1)*SPACING_Y)
    end
  end
end

function drawButton(btn)
  love.graphics.rectangle('line', btn.x, btn.y, btn.w, btn.h)
  love.graphics.printf(btn.label,
    btn.x, btn.y+8, btn.w, 'center')
end

function love.mousepressed(x,y)
  if gameState == 'won' then return end
  if pointInRect(x,y,RESET_BTN) then resetGame() return end
  if pointInRect(x,y,UNDO_BTN)  then undoMove() return end
  handlePress(x,y)
end

function love.mousemoved(x,y)
  mouseX, mouseY = x, y
end

function love.mousereleased(x,y)
  handleRelease(x,y)
end

-- handle mouse‐down: pick up single cards or stacks
function handlePress(x,y)
  local def, idx = findPileUnder(x,y)
  if not def then return end

  if def.type == 'deck' then
    -- click the deck: draw up to 3 cards
    for i = 1, 3 do
      if #drawPile > 0 then
        local c = table.remove(drawPile)
        c.faceUp  = true
        c.srcPile = drawPile           -- ← store actual table
        c.source  = { type='deck' }    -- ← store descriptor
        table.insert(drawnCards, c)
      end
    end

  elseif def.type == 'draw' and #drawnCards > 0 then
    -- pick up the top drawn card
    local c = table.remove(drawnCards)
    c.srcPile = drawnCards
    c.source  = { type='draw' }
    draggingStack = { c }

  elseif def.type == 'tableau' then
    local pile = tableau[idx]
    for j = #pile, 1, -1 do
      -- hit‑test card j
      local x0 = def.x
      local y0 = def.y + (j-1)*SPACING_Y
      local w  = CARD_SCALE * cardBackImage:getWidth()
      local h  = CARD_SCALE * cardBackImage:getHeight()
      if x>=x0 and x<=x0+w
         and y>=y0 and y<=y0+h
         and pile[j].faceUp then

        draggingStack = {}
        local count = #pile
        -- remove cards *starting at j*, always at that same index
        for i = j, count do
          local c = table.remove(pile, j)      -- remove at j, not at #pile
          c.srcPile = pile
          c.source  = { type='tableau', index=idx }
          table.insert(draggingStack, c)
        end
        break
      end
  
  end


  elseif def.type == 'suit' then
    -- pick up the top of a suit pile
    local pile = suitPiles[idx]
    if #pile > 0 then
      local c = table.remove(pile)
      c.srcPile = pile
      c.source  = { type='suit', index=idx }
      draggingStack = { c }
    end
  end
end
-- handle mouse‐up: try to drop; if invalid, return to srcPile
function handleRelease(x,y)
  if not draggingStack then return end

  local def, idx = findPileUnder(x,y)
  local moved = false
  local top   = draggingStack[1]

  -- valid drops onto suit
  if def and def.type=='suit'
     and canDropOnSuit(top, suitPiles[idx]) then
    for _,c in ipairs(draggingStack) do
      table.insert(suitPiles[idx], c)
    end
    moved = true

  -- valid drops onto tableau
  elseif def and def.type=='tableau'
     and canDropOnTableau(top, tableau[idx]) then
    for _,c in ipairs(draggingStack) do
      table.insert(tableau[idx], c)
    end
    moved = true
  end

  if moved then
    -- after a successful tableau move, reveal the new top
    if top.source.type=='tableau' then
      revealTop(tableau[top.source.index])
    end
    recordMove(draggingStack, top.source, def)
    if checkWin() then gameState='won' end

  else
    -- invalid drop: shove each card back into the exact table
    for _,c in ipairs(draggingStack) do
      table.insert(c.srcPile, c)
      c.srcPile = nil   -- optional cleanup
      c.source  = nil   -- optional, if you want to clear it
    end
  end

  draggingStack = nil
end


function findPileUnder(x,y)
  for _,def in ipairs(pileDefs) do
    local w = CARD_SCALE*cardBackImage:getWidth()
    local h = CARD_SCALE*cardBackImage:getHeight()
    if def.type=='tableau' then
      h = h + #tableau[def.index]*SPACING_Y
    end
    if x>=def.x and x<=def.x+w
       and y>=def.y and y<=def.y+h then
      return def, def.index
    end
  end
end

function canDropOnSuit(card,pile)
  if #pile==0 then return card.rank=='A' end
  local top=pile[#pile]
  return card.suit==top.suit
     and rankValue(card.rank)==rankValue(top.rank)+1
end

function canDropOnTableau(card,pile)
  if #pile==0 then return card.rank=='K' end
  local top=pile[#pile]
  return top.faceUp
     and (isRed(card.suit)~=isRed(top.suit))
     and rankValue(card.rank)==rankValue(top.rank)-1
end

function rankValue(r)
  for i,v in ipairs(ranks) do if v==r then return i end end
end

function isRed(s) return s=='hearts' or s=='diamonds' end

function revealTop(pile)
  if #pile>0 and not pile[#pile].faceUp then
    pile[#pile].faceUp = true
  end
end

function checkWin()
  for i=1,4 do if #suitPiles[i]<13 then return false end end
  return true
end

function recordMove(cards,from,to)
  table.insert(moveHistory,{cards=cards,from=from,to=to})
end

function undoMove()
  local m = table.remove(moveHistory)
  if not m then return end
  -- remove from destination
  local dst = getPile(m.to)
  for i=1,#m.cards do table.remove(dst) end
  -- return cards
  local src= getPile(m.from)
  for _,c in ipairs(m.cards) do
    table.insert(src, c)
  end
end

function getPile(def)
  if def.type=='deck' then return drawPile end
  if def.type=='draw' then return drawnCards end
  if def.type=='suit' then return suitPiles[def.index] end
  if def.type=='tableau' then return tableau[def.index] end
end

function resetGame() initBoard() end

function pointInRect(x,y,rect)
  return x>=rect.x and x<=rect.x+rect.w
     and y>=rect.y and y<=rect.y+rect.h
end
