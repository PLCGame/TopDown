require "Map"
require "list"
require "SpriteFrame"
require "PriorityQueue"

local map = nil
local sprites = nil
local path = nil

function love.load()
	map = Map.new(require("level0"), nil)

	width, height = love.window.getDimensions()
	map:setSize(width, height)

	sprites = SpriteFrame.new(love.graphics.newImage("Sprite image.png"), love.graphics.newImage("Sprite mask.png"), love.graphics.newImage("Sprite mark.png"))

	path = map:AStar({x = 1, y = 1}, {x = 14, y = 14})
end

function love.update(dt)
end

function love.draw()
	map:draw()

	for k,v in ipairs(path) do

    	love.graphics.draw(sprites.frames[0].image, sprites.frames[0].quad, v.x * 32, v.y * 32, 0, 1.0, 1.0, -8, -8)		
	end


   	love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("Path finding A* test", 10, 10)
end