-- main.lua

local CARD_SCALE = 0.1

function love.load()
    love.graphics.setBackgroundColor(0, 0.6, 0)

    cardImages = {}
    suits = {"spades", "hearts", "clubs", "diamonds"}
    ranks = {"ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"}
    redSuits = {hearts = true, diamonds = true}

    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            local filename = rank .. "_of_" .. suit .. ".png"
            cardImages[rank .. "_of_" .. suit] = love.graphics.newImage("assets/" .. filename)
        end
    end

    backImage = love.graphics.newImage("assets/back.png")

    deck = {}
    tableau = {}
    suitPiles = {{}, {}, {}, {}}
    drawPile = {}
    drawnCards = {}

    draggingCard = nil
    draggingStack = nil
    dragOffsetX, dragOffsetY = 0, 0
    dragX, dragY = 0, 0

    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            table.insert(deck, {suit=suit, rank=rank, faceUp=false})
        end
    end

    for i = #deck, 2, -1 do
        local j = love.math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end

    for i = 1, 7 do
        tableau[i] = {}
        for j = 1, i do
            local card = table.remove(deck)
            card.faceUp = (j == i)
            table.insert(tableau[i], card)
        end
    end
end

function drawCard(x, y, card)
    if card.faceUp then
        local key = card.rank .. "_of_" .. card.suit
        love.graphics.draw(cardImages[key], x, y, 0, CARD_SCALE, CARD_SCALE)
    else
        love.graphics.draw(backImage, x, y, 0, CARD_SCALE, CARD_SCALE)
    end
end

function isRed(suit)
    return redSuits[suit] == true
end

function love.draw()
    if #deck > 0 then
        love.graphics.draw(backImage, 50, 50, 0, CARD_SCALE, CARD_SCALE)
    end

    for i, card in ipairs(drawnCards) do
        drawCard(120 + (i-1)*30, 50, card)
    end

    local screenH = love.graphics.getHeight()
    for i = 1, 4 do
        local pile = suitPiles[i]
        if #pile > 0 then
            drawCard(50 + (i-1)*80, screenH - 150, pile[#pile])
        else
            love.graphics.draw(backImage, 50 + (i-1)*80, screenH - 150, 0, CARD_SCALE, CARD_SCALE)
        end
    end

    for i = 1, 7 do
        local pile = tableau[i]
        for j, card in ipairs(pile) do
            drawCard(50 + (i-1)*80, 150 + (j-1)*30, card)
        end
    end

    if draggingStack then
        for i, card in ipairs(draggingStack) do
            drawCard(dragX, dragY + (i-1)*30, card)
        end
    elseif draggingCard then
        drawCard(dragX, dragY, draggingCard)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Click deck to draw
        if x >= 50 and x <= 50 + backImage:getWidth() * CARD_SCALE and
           y >= 50 and y <= 50 + backImage:getHeight() * CARD_SCALE and
           #deck > 0 then
            for i = 1, 3 do
                if #deck == 0 then break end
                local card = table.remove(deck)
                card.faceUp = true
                table.insert(drawnCards, card)
            end
            return
        end

        -- Click top drawn card
        if #drawnCards > 0 then
            local cardX = 120 + (#drawnCards - 1) * 30
            local cardY = 50
            local w = backImage:getWidth() * CARD_SCALE
            local h = backImage:getHeight() * CARD_SCALE

            if x >= cardX and x <= cardX + w and y >= cardY and y <= cardY + h then
                draggingCard = table.remove(drawnCards)
                draggingCard.source = i
                dragOffsetX = x - cardX
                dragOffsetY = y - cardY
                dragX, dragY = cardX, cardY
                return
            end
        end

        -- Click face-up tableau card to drag stack
        for i = 1, 7 do
            local pile = tableau[i]
            for j = #pile, 1, -1 do
                local card = pile[j]
                if card.faceUp then
                    local cardX = 50 + (i - 1) * 80
                    local cardY = 150 + (j - 1) * 30
                    local w = backImage:getWidth() * CARD_SCALE
                    local h = backImage:getHeight() * CARD_SCALE
                    if x >= cardX and x <= cardX + w and y >= cardY and y <= cardY + h then
                        draggingStack = {}
                        for k = j, #pile do
                            table.insert(draggingStack, pile[k])
                        end
                        for k = #pile, j, -1 do
                            table.remove(pile)
                        end
                        draggingStack.source = i
                        dragOffsetX = x - cardX
                        dragOffsetY = y - cardY
                        dragX, dragY = cardX, cardY
                        return
                    end
                end
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if draggingCard or draggingStack then
        dragX = x - dragOffsetX
        dragY = y - dragOffsetY
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and (draggingCard or draggingStack) then
        local screenH = love.graphics.getHeight()
        local moved = false

        local cardToPlace = draggingCard or (draggingStack and draggingStack[1])

        -- Try suit piles
        if draggingCard or (draggingStack and #draggingStack == 1) then
            local cardToPlace = draggingCard or draggingStack[1]
            for i = 1, 4 do
                local tx = 50 + (i - 1) * 80
                local ty = screenH - 150
                local pile = suitPiles[i]
                local top = pile[#pile]

                if x >= tx and x <= tx + 50 and y >= ty and y <= ty + 70 then
                    if (#pile == 0 and cardToPlace.rank == "ace") or
                       (#pile > 0 and cardToPlace.suit == top.suit and
                        getRankIndex(cardToPlace.rank) == getRankIndex(top.rank) + 1) then
                        table.insert(pile, cardToPlace)
                        moved = true
                        draggingCard = nil
                        draggingStack = nil
                        break
                    end
                end
            end
        end


        -- Tableau drop
        if not moved then
            for i = 1, 7 do
                local tx = 50 + (i - 1) * 80
                local ty = 150 + (#tableau[i] > 0 and (#tableau[i]-1)*30 or 0)
                local pile = tableau[i]
                local top = pile[#pile]
                if x >= tx and x <= tx + 50 and y >= ty and y <= ty + 70 then
                    if #pile == 0 and cardToPlace.rank == "king" then
                        for _, c in ipairs(draggingStack or {cardToPlace}) do
                            table.insert(pile, c)
                        end
                        moved = true
                    elseif #pile > 0 and top.faceUp and
                           isRed(cardToPlace.suit) ~= isRed(top.suit) and
                           getRankIndex(cardToPlace.rank) == getRankIndex(top.rank) - 1 then
                        for _, c in ipairs(draggingStack or {cardToPlace}) do
                            table.insert(pile, c)
                        end
                        moved = true
                    end
                end
            end
        end

        if not moved then
            if draggingCard and draggingCard.source == "draw" then
                table.insert(drawnCards, draggingCard)
            elseif draggingCard and draggingCard.source and draggingCard.source:match("^tableau%d$") then
                local i = tonumber(draggingCard.source:match("%d+"))
                table.insert(tableau[i], draggingCard)
            elseif draggingStack and draggingStack.source then
                for _, c in ipairs(draggingStack) do
                    table.insert(tableau[draggingStack.source], c)
                end
            end
        else
            -- Reveal card behind after valid move
            local sourceIndex = nil
            if draggingCard and draggingCard.source and type(draggingCard.source) == "number" then
                sourceIndex = draggingCard.source
            elseif draggingStack and draggingStack.source then
                sourceIndex = draggingStack.source
            end

            if sourceIndex then
                local originalPile = tableau[sourceIndex]
                if #originalPile > 0 and not originalPile[#originalPile].faceUp then
                    originalPile[#originalPile].faceUp = true
                end
            end

        end

        draggingCard = nil
        draggingStack = nil
    end
end

function getRankIndex(rank)
    for i, r in ipairs(ranks) do
        if r == rank then return i end
    end
    return -1
end
