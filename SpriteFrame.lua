SpriteFrame = {}
SpriteFrame.__index = SpriteFrame

function extractFrameFromImage(data, startX, startY)
	x = startX
	y = startY

	r, g, b, a = data:getPixel(x, y)

	-- the width
	while x < data:getWidth() and r == 255 and b == 255 do 
		x = x + 1
		r, g, b, a = data:getPixel(x, startY)
	end

	-- initial pixel
	r, g, b, a = data:getPixel(startX, startY)
	-- the height
	while y < data:getHeight() and r == 255 and b == 255 do 
		y = y + 1
		r, g, b, a = data:getPixel(startX, y)
	end

	local frame = {}
	frame.x = startX
	frame.y = startY
	frame.width = x - startX
	frame.height = y - startY

	return frame
end

function frameSort(f1, f2)
	-- y sort first
	if f1.y + f1.height < f2.y then 
		return true
	end

	if f2.y + f2.height < f1.y then
		return false
	end

	-- they are on the same "row"
	if f1.x + f1.width < f2.x then
		return true
	end

	-- else 
	return false
end

function pixelIsMask(data, x, y)
	if x < 0 then
		return false
	end

	if y < 0 then
		return false
	end

	-- else test pixel color
	r, g, b, a = data:getPixel(x, y)

	return r == 255 and g == 0 and b == 255
end

-- create frame from images
function extractFramesFromImage(image)
	data = image:getData()
	local frames = {}

	for y = 0, data:getHeight() -1 do
		for x = 0, data:getWidth() -1 do
			if pixelIsMask(data, x, y) and not pixelIsMask(data, x - 1, y) and not pixelIsMask(data, x, y - 1) then
				-- it's a new frame, extract it
				frame = extractFrameFromImage(data, x, y)
				table.insert(frames, frame)

				-- increment x
			end
		end
	end

	table.sort(frames, frameSort )
	return frames
end


function extractMarkFromFrame(data, frame)
	frame.xoffset = 0
	frame.yoffset = 0

	for y = frame.y, frame.y + frame.height do
		for x = frame.x, frame.x + frame.width do
			r, g, b, a = data:getPixel(x, y)
			if a == 255 then
				frame.xoffset = frame.x - x
				frame.yoffset = frame.y - y
			end
		end
	end

	return frame
end

function extractMarksFromFrame(image, frames)
	data = image:getData()

	for i, frame in ipairs(frames) do 
		frame = extractMarkFromFrame(data, frame)
	end
end

function SpriteFrame.new(spriteImage, maskImage, markImage)
	local self = setmetatable({}, SpriteFrame)

	-- extract frame and mark
	local frames = extractFramesFromImage(maskImage)
	extractMarksFromFrame(markImage, frames)

	-- create sprite
	self.frames = {}
	for i = 1, #frames do
		--print("-------------------------------")
		--print("Frame", i)
		--print(frames[i].x, frames[i].y)
		--print(frames[i].width, frames[i].height)
		--print(frames[i].xoffset, frames[i].yoffset)	

		local spriteFrame = {}
		spriteFrame.image = spriteImage
		spriteFrame.quad = love.graphics.newQuad(frames[i].x, frames[i].y, frames[i].width, frames[i].height, spriteImage:getWidth(), spriteImage:getHeight())
		spriteFrame.xoffset = frames[i].xoffset
		spriteFrame.yoffset = frames[i].yoffset	

		table.insert(self.frames, i - 1, spriteFrame)
	end

	return self
end

