--------------------------------------------------------------------
-------------------- HOW TO USE THE BRUSH --------------------
--------------------------------------------------------------------

-- The usage of the brush should be straightforward.
-- To add blocks that should be treated as foliage, 
-- they must be added to the foliage table below.
-- Only blocks added to this list will be recognized as foliage 
-- if eraser mode or replace existing foliage is toggled.
-- Also, the brush will not place anything on top of blocks 
-- contained in this list.

local foliageTable = {
	blocks.conquest.grass,
	blocks.conquest.greater_fen_sedge,
	blocks.conquest.timothy_grass
}

-- To exclude more blocks where nothing should be placed on top of 
-- by the brush, add them to the following table:
local nonSolidBlocksTable = {
	blocks.air,
   	blocks.water
}

-- If Two Tall Amount and Three Tall Amount add up to less than 1,
-- the remaining amount will result in one-tall foliage. If the sum exceeds 1, 
-- no one-tall foliage will be placed. Instead, the ratio 
-- between Two Tall Amount and Three Tall Amount will determine 
-- the distribution. For example, if Two Tall Amount = 0.4 and 
-- Three Tall Amount = 0.8, then 1/3 of the foliage will be two-tall, 
-- and 2/3 will be three-tall.

------------------------ End of explanation ------------------------



-- Load custom arguments
local foliage = $blockState(Foliage, air)$
local noise_size = $int(Noise Size,7,1,20)$
local noise_density = $float(Noise Density,0.5,0,1)$
local random_amount = $float(Random Amount,0.8,0,1)$
local allow_two_tall = $boolean(Allow two/three tall,false)$
local two_tall_amount = $float(Two Tall Amount,0.7,0,1)$
local three_tall_amount = $float(Three Tall Amount,0.1,0,1)$
local noise = getSimplexNoise(x/noise_size, y/noise_size, z/noise_size)
local replaceMode =  $boolean(Replace existing foliage,false)$
local eraserMode =  $boolean(Toggle eraser mode,false)$

-- Function to check if a value is contained within a table
local function contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function that places grass with the correct "layers" property at coordinates (a, b, c).
-- The function sets the "layers" property of the foliage to match the block beneath it.
-- If the block below does not have a "layers" property, the condition
-- getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=n")
-- will always evaluate to true, which is why it must first be checked for"layers=8" .
function setGrass(a, b, c, grassType)
    if getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=8") then
		local block = withBlockProperty(grassType, "layers=8")
       	setBlock(a, b, c, block)
	elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=1") then
       	local block = withBlockProperty(grassType, "layers=1")
       	setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=2") then
       local block = withBlockProperty(grassType, "layers=2")
       setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=3") then
        local block = withBlockProperty(grassType, "layers=3")
       	setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=4") then
        local block = withBlockProperty(grassType, "layers=4")
       	setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=5") then
        local block = withBlockProperty(grassType, "layers=5")
       setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=6") then
        local block = withBlockProperty(grassType, "layers=6")
        setBlock(a, b, c, block)
    elseif getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, y - 1, z), "layers=7") then
        local block = withBlockProperty(grassType, "layers=7")
       	setBlock(a, b, c, block)
    else
        return nil 
    end
end

if eraserMode == true then
	if contains(foliageTable, getBlock(x, y, z)) then
		return blocks.air
	else
		return nil
	end
end

-- Ensure the target block is air before placing foliage
if getBlock(x, y, z) ~= blocks.air then
	return nil
end

-- Ensure the block below is a solid block (i.e. not contained
-- in nonSolidBlocksTable)
if contains(nonSolidBlocksTable, getBlock(x, y-1, z)) then
    return nil
end

-- If two_tall_amount and three_tall_amount exceed a total of 1, 
-- they are normalized to ensure their ratio remains consistent 
-- while adding up to 1.
local sum = two_tall_amount + three_tall_amount
if sum > 1 then
	two_tall_amount = two_tall_amount / sum
	three_tall_amount = three_tall_amount / sum
end

-- Foliage placement occurs here.
-- It checks if foliage should be placed based on the 
-- random amount and noise values.
if math.random() < random_amount and noise < noise_density then
	-- Random variable to control two and three tall placements
	local random = math.random()
	
	if not contains(foliageTable, getBlock(x, y-1, z)) then

		if allow_two_tall == true then
			-- Based on the random value, foliage height is randomized 
			-- between two-tall and three-tall proportions.
			if random < three_tall_amount then
				setGrass(x, y, z, foliage)
				setGrass(x, y + 1, z, foliage)
				setGrass(x, y + 2, z, foliage)
			elseif random < sum then
				setGrass(x, y, z, foliage)
				setGrass(x, y + 1, z, foliage)
			else
				setGrass(x, y, z, foliage)
			end
		else
			setGrass(x, y, z, foliage)
		end

	elseif replaceMode == true then

		if allow_two_tall == true then
			-- Based on the random value, foliage height is randomized 
			-- between two-tall and three-tall proportions.
			if random < three_tall_amount then
				setGrass(x, y-1, z, foliage)
				setGrass(x, y, z, foliage)
				setGrass(x, y + 1, z, foliage)
			elseif random < sum then
				setGrass(x, y-1, z, foliage)
				setGrass(x, y, z, foliage)
			else
				setGrass(x, y-1, z, foliage)
			end
		else
			setGrass(x, y-1, z, foliage)
		end

	-- If there is a foliage block below and replace mode is not toggled,
	-- the program will return nil
	else
		return nil
	end
-- If the conditions for random amount and noise are not met,
-- the program will return nil
else
	return nil
end



