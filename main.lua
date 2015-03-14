require "Map"
require "list"
require "SpriteFrame"
require "PriorityQueue"

local map = nil
local sprites = nil
local path = nil
local search = nil

function love.load()
	map = Map.new(require("level0"), nil)

	width, height = love.window.getDimensions()
	map:setSize(width, height)

	sprites = SpriteFrame.new(love.graphics.newImage("Sprite image.png"), love.graphics.newImage("Sprite mask.png"), love.graphics.newImage("Sprite mark.png"))

	local reach = false
	path,reach, search = map:AStar({x = 0, y = 0}, {x = 15, y = 15})
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
		love.graphics.print(v.priority, v.pos.x * map.tile_width + 8, v.pos.y * map.tile_height + 8)
	end


    love.graphics.print("Path finding A* test", 10, 10)
end