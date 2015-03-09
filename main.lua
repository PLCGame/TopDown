require "Map"

local map = nil

function love.load()
	map = Map.new(require("level0"), nil)
	map:setSize()
end

function love.update(dt)
end

function love.draw()
	map:draw()

	love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("Path finding A* test", 10, 10)
end