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

local pawn = nil
local scene_objects = {}

function computePath()
	local reach = false
	path,reach, search = map:AStar(start_tile, end_tile)

	print(start_tile.x, start_tile.y, end_tile.x, end_tile.y)
end

function love.load()
	map = Map.new(require("level0"), nil)

	width, height = love.graphics.getDimensions()
	map:setSize(width, height)

	sprites = SpriteFrame.new(love.graphics.newImage("Sprite image.png"), love.image.newImageData("Sprite mask.png"), love.image.newImageData("Sprite mark.png"))

	start_tile = {x=0, y=0}
	end_tile = {x = 15,y = 15}

	computePath()

	pawn = {
		sprite = sprites.frames[1], 
		position = {x=0, y=0}
	}

	table.insert(scene_objects, pawn)
end

function love.mousepressed(x, y, button)
	-- make it in map coordinate
	local mx = math.min(math.floor(x / map.tile_width), map.width - 1)
	local my = math.min(math.floor(y / map.tile_height), map.height - 1)

	print(button, x, y, mx, my)

	start_tile.x = math.floor(pawn.position.x / map.tile_width)
	start_tile.y = math.floor(pawn.position.y / map.tile_height)

	if button == 1 then
		end_tile.x = mx
		end_tile.y = my
	end

	computePath()
end

function love.update(dt)
	if #path == 0 then
		return
	end

	-- move sprite along the path
	local pos = pawn.position
	local dest = path[#path]

	--print(dest.x, dest.y)

	local _dest = {x=0, y=0}
	_dest.x = (dest.x + 0.5) * map.tile_width
	_dest.y = (dest.y + 0.5) * map.tile_height

	local dir = {x = _dest.x - pos.x, y = _dest.y - pos.y}

	-- normalize
	local a = math.sqrt(dir.x * dir.x + dir.y * dir.y)

	if a > 1.0 then
		a = 128.0 * dt / a
		local speed = {x = dir.x * a, y = dir.y * a}
		pawn.position.x = pawn.position.x + speed.x
		pawn.position.y = pawn.position.y + speed.y	
	else 
		table.remove(path)
	end

	--print(pawn.position.x, pawn.position.y)
end

function love.draw()
	love.graphics.setColor(255, 255, 255, 255)

	-- draw the map
	map:draw()

	-- draw sprites
	for k,obj in ipairs(scene_objects) do
		love.graphics.draw(obj.sprite.image, obj.sprite.quad, obj.position.x, obj.position.y, 0, 1.0, 1.0, -obj.sprite.xoffset, -obj.sprite.yoffset)
	end	


	for k,v in ipairs(path) do
    	love.graphics.draw(sprites.frames[0].image, sprites.frames[0].quad, v.x * 32, v.y * 32, 0, 1.0, 1.0, -8, -8)		
	end

	for k,v in ipairs(search) do
		local str = k
		love.graphics.print(str, v.pos.x * map.tile_width + 8, v.pos.y * map.tile_height + 8)
	end

    --love.graphics.print("Path finding A* test", 10, 10)
end