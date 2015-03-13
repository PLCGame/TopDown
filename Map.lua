require "PriorityQueue"

Map = {}
Map.__index = Map

function AABBOverlap(A, B)
	local Tx = (A.min[0] + A.max[0]) * 0.5 - (B.min[0] + B.max[0]) * 0.5
	local Ty = (A.min[1] + A.max[1]) * 0.5 - (B.min[1] + B.max[1]) * 0.5

	local width = (A.max[0] - A.min[0]) * 0.5 + (B.max[0] - B.min[0]) * 0.5
	local height = (A.max[1] - A.min[1]) * 0.5 + (B.max[1] - B.min[1]) * 0.5

	if math.abs(Tx) < width and math.abs(Ty) < height then
		return true
	end

	return false
end

function AABBSweepTest(A, vA, B, vB)
	local xInvEntry, yInvEntry
	local xInvExit, yInvExit

	-- distance between object
	if vA[0] > 0 then
		xInvEntry = B.min[0] - A.max[0]
		xInvExit = B.max[0] - A.min[0]
	else
		xInvEntry = B.max[0] - A.min[0]
		xInvExit = B.min[0] - A.max[0]
	end

	if vA[1] > 0 then
		yInvEntry = B.min[1] - A.max[1]
		yInvExit = B.max[1] - A.min[1]
	else
		yInvEntry = B.max[1] - A.min[1]
		yInvExit = B.min[1] - A.max[1]
	end

	-- collision time
	local xEntry, yEntry
	local xExit, yExit

	if vA[0] == 0.0 then
		xEntry = -1e6
		xExit = 1e6
	else
		xEntry = xInvEntry / vA[0]
		xExit = xInvExit / vA[0]
	end

	if vA[1] == 0.0 then
		yEntry = -1e6
		yExit = 1e6
	else
		yEntry = yInvEntry / vA[1]
		yExit = yInvExit / vA[1]
	end

	local entryTime = math.max(xEntry, yEntry)
	local exitTime = math.min(xExit, yExit)

	-- if there's no collision
	if entryTime > exitTime or xEntry < 0.0 and yEntry < 0.0 or xEntry > 1.0 or yEntry > 1.0 then
		return 1.0, 0
	end

	-- else
	local n = 0
	-- collision
	if xEntry > yEntry then
		n = 0
	else
		n = 1
	end
	
	return entryTime, n
end

function loadTileset(data)
	local tileset = {}

	tileset.image = love.graphics.newImage(data.image)
	tileset.image:setFilter("nearest", "nearest") 

	-- create the quad
	sw = tileset.image:getWidth() / data.tilewidth
	sh = tileset.image:getHeight() / data.tileheight

	tileset.tiles = {}
	for y = 0, sh do 
		for x = 0, sw do
			tileset.tiles[x + y * sw] = {}
			tileset.tiles[x + y * sw].quad = love.graphics.newQuad(x * data.tilewidth, y * data.tileheight, data.tilewidth, data.tileheight, tileset.image:getWidth(), tileset.image:getHeight())
		end
	end

	-- loop trough properties
	for i, tile in ipairs(data.tiles) do
		--tileset.tiles[tile.id].collision = tonumber(tile.properties["collision"])

		if tile.properties ~= nil then
			tileset.tiles[tile.id].type = tile.properties["type"]
		end

		-- use Tiled tile editor
		-- start with nil, no collision
		tileset.tiles[tile.id].collision = nil

		-- just use one object per tile by now
		if tile.objectGroup ~= nil and #tile.objectGroup.objects > 0 and tile.objectGroup.objects[1].shape == "rectangle" then
			local aabb = { min = {}, max = {} }
			aabb.min[0] = tile.objectGroup.objects[1].x
			aabb.max[0] = tile.objectGroup.objects[1].x + tile.objectGroup.objects[1].width
			aabb.min[1] = tile.objectGroup.objects[1].y
			aabb.max[1] = tile.objectGroup.objects[1].y + tile.objectGroup.objects[1].height

			tileset.tiles[tile.id].collision = aabb
		end
	end

	return tileset
end

function Map.new(mapData, entityFactory) 
	local self = setmetatable({}, Map)

	-- default values
	self.screen_width = 256
	self.screen_height = 192

	self.dx = 0
	self.dy = 0

	self.width = mapData.width
	self.height = mapData.height
	self.tile_width = mapData.tilewidth
	self.tile_height = mapData.tileheight

	-- load tile set
	self.backgroundTiles = loadTileset(mapData.tilesets[1])

	-- create background tile map
	local backgroundLayer = mapData.layers[1]
	self.backgroundMap = {}

	for i = 0, self.width * self.height - 1 do
		self.backgroundMap[i] = backgroundLayer.data[1 + i] - 1
	end

	-- create object map
	local objectLayer = mapData.layers[2]
	if objectLayer ~= nil then
		self.objectTiles = loadTileset(mapData.tilesets[2])

		self.objectsMap = {}
		for i = 0, self.width * self.height - 1 do
			self.objectsMap[i] = objectLayer.data[1 + i] - mapData.tilesets[2].firstgid
		end
	end

	-- parse object layers
	local spawnLayer = mapData.layers[3]
	if spawnLayer ~= nil then
		for i = 1, #spawnLayer.objects do
			local obj = spawnLayer.objects[i]

			--print(obj.type)

			-- create the entity
			local x = obj.x + obj.width * 0.5
			local y = obj.y + obj.height
			entityFactory:spawnEntity(obj.type, x, y)
		end
	end

	return self
end

-- draw the map
-- x, y position on the screen 
-- width, height size in pixels
-- dx, dy scrolling position
function Map:draw()
	tilex = math.floor(self.dx / self.tile_width)
	tiley = math.floor(self.dy / self.tile_height)
	tilew = math.min(self.screen_width / self.tile_width, self.width - 1 - tilex)
	tileh = math.min(self.screen_height / self.tile_height, self.height-1 - tiley)

	-- draw background
	for ty = 0, tileh do 
		for tx = 0, tilew do
			tile = self.backgroundTiles.tiles[self.backgroundMap[(tx + tilex) + (ty + tiley) * self.width]]

			if tile == nil then
				print(tilex, tiley, tilew, tileh)
			end

			love.graphics.draw(self.backgroundTiles.image, tile.quad, (tx + tilex) * self.tile_width - self.dx, (ty + tiley) * self.tile_height - self.dy, 0, 1.0, 1.0, 0.0, 0.0)
		end
	end

	-- draw objects
	if self.objectsMap ~= nil then
		for ty = 0, tileh do 
			for tx = 0, tilew do
				tile = self.objectTiles.tiles[self.objectsMap[(tx + tilex) + (ty + tiley) * self.width]]

				if tile ~= nil then			
					love.graphics.draw(self.objectTiles.image, tile.quad, (tx + tilex) * self.tile_width - self.dx, (ty + tiley) * self.tile_height - self.dy, 0, 1.0, 1.0, 0.0, 0.0)
				end
			end
		end
	end

end

function Map:setSize(width, height)
	self.screen_width = width
	self.screen_height = height
end

function Map:scrollTo(object)
	self.dx = math.min(math.max(object.x + object.width * 0.5 - 128, 0), self.dx) -- lower x bound
	self.dx = math.max(math.min(object.x + object.width * 0.5 + 128 - self.screen_width, self.width * self.tile_width - self.screen_width), self.dx) -- higher x bound

	self.dy = math.min(math.max(object.y - object.height - 64, 0), self.dy) -- lower y bound
	self.dy = math.max(math.min(object.y + 64 - self.screen_height, self.height * self.tile_height - self.screen_height), self.dy) -- higher x bound
end

-- return the type of tile (ladder, etc)
function Map:tileType(x, y)
	local clampX = math.max(0, math.min(self.width - 1, x))
	local clampY = math.max(0, math.min(self.height - 1, y))

	return self.backgroundTiles.tiles[self.backgroundMap[clampX + clampY * self.width]].type
end

-- return distance to center, distance up, distance down
-- return nil if there's no ladder next to the entity
function Map:distanceToLadder(entity)
	local xmin = math.floor((entity.x - entity.width * 0.5) / self.tile_width)
	local xmax = math.floor((entity.x + entity.width * 0.5-1) / self.tile_width)
	local ymin = math.floor((entity.y - entity.height) / self.tile_height)
	local ymax = math.floor(entity.y / self.tile_height)

	for y = ymin, ymax do
		for x = xmin, xmax do
			if self:tileType(x, y) == "ladder" then
				-- we found a valid ladder tile
				local distanceToCenter = (x + 0.5) * self.tile_width - entity.x

				local distanceToBottom = (y + 1) * self.tile_height - entity.y
				local _y = y + 1
				while _y < self.height and self:tileType(x, _y) == "ladder" do
					_y = _y + 1
					distanceToBottom = distanceToBottom + self.tile_height
				end

				local distanceToTop = entity.y - y * self.tile_height
				_y = y - 1
				while _y >= 0 and self:tileType(x, _y) == "ladder" do
					_y = _y - 1
					distanceToTop = distanceToTop + self.tile_height
				end

				return distanceToCenter, distanceToTop, distanceToBottom
			end
		end
	end

	-- no ladder tile
	return nil
end

-- return the AABB for the tile at x, y
function Map:AABBForTile(x, y)
	local clampX = math.max(0, math.min(self.width - 1, x))
	local clampY = math.max(0, math.min(self.height - 1, y))

	local col_aabb = self.backgroundTiles.tiles[self.backgroundMap[clampX + clampY * self.width]].collision
	local aabb = { min = {}, max = {} }

	if col_aabb ~= nil then
		aabb.min[0] = x * self.tile_width + col_aabb.min[0]
		aabb.max[0] = x * self.tile_width + col_aabb.max[0]
		aabb.min[1] = y * self.tile_height + col_aabb.min[1]
		aabb.max[1] = y * self.tile_height + col_aabb.max[1]

		return aabb
	end

	-- else
	return nil
end

-- Cast an AABB in the map along v
-- type is the type of tile to ignore 
function Map:AABBCast(aabb, v, tileType)
	-- get the tiles
	tilesAABB = { min = {}, max = {} }

	for i = 0, 1 do
		if v[i] < 0 then
			tilesAABB.min[i] = aabb.min[i] + v[i]
			tilesAABB.max[i] = aabb.max[i]
		else
			tilesAABB.min[i] = aabb.min[i]
			tilesAABB.max[i] = aabb.max[i] + v[i]
		end
	end

	tile_min = {}
	tile_max = {}
	tile_min[0] = math.floor(tilesAABB.min[0] / self.tile_width)
	tile_max[0] = math.floor(tilesAABB.max[0] / self.tile_width)

	tile_min[1] = math.floor(tilesAABB.min[1] / self.tile_height)
	tile_max[1] = math.floor(tilesAABB.max[1] / self.tile_height)

	-- iterate on the tile and do the cast for each of them
	normal = 0
	u = 1.0
	for y = tile_min[1], tile_max[1] do
		for x = tile_min[0], tile_max[0] do
			if tileType == nil or self:tileType(x, y) ~= tileType then
				tileAABB = self:AABBForTile(x, y)

				if tileAABB ~= nil and AABBOverlap(tileAABB, tilesAABB) then
					--print("tile : ", x, y, tileAABB.min[1], tileAABB.max[1])

					_u, _normal = AABBSweepTest(aabb, v, tileAABB, {[0] = 0, [1] = 0})

					if _u < 1.0 then
						if _u < u then
							normal = _normal
							u = _u
						end
					end
				end
			end
		end
	end

	--print("cast result", u, v[0], v[1])

	return u, normal
end

function Map:PointIdx(p)
	return p.y * self.width + p.x
end

function Map:IdxPoint(idx) 
	local x = idx % self.width
	local y = (idx - x) / self.width
	return {x = x, y = y}
end

function Map:TileNeightbors(tile_idx)
	local neightbors = {}

	-- up
	if tile_idx - self.width >= 0 and self.backgroundTiles.tiles[self.backgroundMap[tile_idx - self.width]].collision == nil then
		table.insert(neightbors, tile_idx - self.width)
	end

	-- bottom
	if tile_idx + self.width < self.width * self.height and self.backgroundTiles.tiles[self.backgroundMap[tile_idx + self.width]].collision == nil then
		table.insert(neightbors, tile_idx + self.width)
	end

	-- left
	if tile_idx - 1 >= 0 and self.backgroundTiles.tiles[self.backgroundMap[tile_idx - 1]].collision == nil then
		table.insert(neightbors, tile_idx - 1)
	end

	-- right
	if tile_idx + 1 < width and self.backgroundTiles.tiles[self.backgroundMap[tile_idx + 1]].collision == nil then
		table.insert(neightbors, tile_idx + 1)
	end

	return neightbors
end

function Map:heuristic(a, b)
	local pA = self:IdxPoint(a)
	local pB = self:IdxPoint(b)

	return math.max(math.abs(pA.x - pB.x), math.abs(pA.y - pB.y))
	--return 0.0
end

function Map:AStar(start, goal)
	local closedSet = {}
	local q = PriorityQueue.new()
	local came_from = {}
	local score = {}

	local start_idx = self:PointIdx(start)
	local goal_idx = self:PointIdx(goal)

	local best = {idx = start_idx, score = self:heuristic(start_idx, goal_idx)}

	score[start_idx] = 0
	q:push(start_idx, 0)
	came_from[start_idx] = -1

	local count = 0

	while #q > 0 do
		local current, p = q:pop()
		local currentPoint = self:IdxPoint(current)
		--print("current :", currentPoint.x, currentPoint.y, p)

		local s = self:heuristic(goal_idx, current)
		if s < best.score then
			best.idx = current
			best.score = self:heuristic(goal_idx, current)
		end

		if current == goal_idx then
			break
		end

		-- add to closed set
		closedSet[current] = true

		local neightbors = self:TileNeightbors(current)
		for key,n in pairs(neightbors) do
			if closedSet[n] == nil then
				local newScore = score[current] + 1 -- 1 is the disantce between node

				if came_from[n] == nil or newScore < score[n] then
					came_from[n] = current
					score[n] = newScore
					--print(score[n], self:heuristic(goal_idx, n))
					q:push(n, score[n] + self:heuristic(goal_idx, n))
				end
			end
		end

		count = count + 1
	end


	-- return the path
	local path = {}
	local idx = best.idx
	while idx ~= -1 do
		table.insert(path, self:IdxPoint(idx))
		idx = came_from[idx]
	end

	print(#path, count)

	return path, best.idx == goal_idx
end
