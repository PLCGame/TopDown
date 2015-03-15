require "Map"
require "list"
require "SpriteFrame"
require "PriorityQueue"

local map = nil
local sprites = nil
local path = nil
local search = nil
local start_tile = nil
local end_tile = nil

function computePath()
	local reach = false
	path,reach, search = map:AStar(start_tile, end_tile)

	print(start_tile.x, start_tile.y, end_tile.x, end_tile.y)
end

function love.load()
	map = Map.new(require("level0"), nil)

	width, height = love.window.getDimensions()
	map:setSize(width, height)

	sprites = SpriteFrame.new(love.graphics.newImage("Sprite image.png"), love.graphics.newImage("Sprite mask.png"), love.graphics.newImage("Sprite mark.png"))

	start_tile = {x=0, y=0}
	end_tile = {x = 15,y = 15}

	computePath()
end

function love.mousepressed(x, y, button)
	-- make it in map coordinate
	local mx = math.min(math.floor(x / map.tile_width), map.width - 1)
	local my = math.min(math.floor(y / map.tile_height), map.height - 1)

	print(button, x, y, mx, my)

	if button == "l" then
		end_tile.x = mx
		end_tile.y = my
	end

	computePath()
end

function love.update(dt)
end

function love.draw()
	love.graphics.setColor(255, 255, 255, 255)
	map:draw()

	for k,v in ipairs(path) do
    	love.graphics.draw(sprites.frames[0].image, sprites.frames[0].quad, v.x * 32, v.y * 32, 0, 1.0, 1.0, -8, -8)		
	end

	for k,v in ipairs(search) do
		local str = k
		love.graphics.print(str, v.pos.x * map.tile_width + 8, v.pos.y * map.tile_height + 8)
	end


    --love.graphics.print("Path finding A* test", 10, 10)
end