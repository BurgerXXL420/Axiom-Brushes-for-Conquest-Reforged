--------------------------------------------------------------------
---------------------- CONQUEST PLANTS BRUSH -----------------------
--------------------------------------------------------------------

-- To save a preset you have to change the default values for the various parameters of the brush directly here in the code
-- The default value to change is always the first value (block id, number, boolean) after the name of the parameter shown in the UI

local plant_table = {
    $blockState(Plant1, conquest:green_meadow_fescue)$,
    $blockState(Plant2, conquest:dry_reeds)$,
    $blockState(Plant3, conquest:common_meadow_grass)$,
    $blockState(Plant4, conquest:grass)$,
    $blockState(Plant5, conquest:timothy_grass)$,
    $blockState(Plant6, conquest:tall_grass)$
}

local plant_amounts_table = {
    $float(Plant 1 Amount, 0.5, 0, 1)$, -- The default is 0.5; change this value
    $float(Plant 2 Amount, 0.5, 0, 1)$,
    $float(Plant 3 Amount, 0.5, 0, 1)$,
    $float(Plant 4 Amount, 0.5, 0, 1)$,
    $float(Plant 5 Amount, 0.5, 0, 1)$,
    $float(Plant 6 Amount, 0.5, 0, 1)$
}

local two_three_tall_amounts_table = {
    $float(Two Tall Amount 1, 0.7, 0, 1)$, -- The default is 0.7; change this value
    $float(Three Tall Amount 1, 0.1, 0, 1)$, -- The default is 0.1; change this value
    $float(Two Tall Amount 2, 0.7, 0, 1)$,
    $float(Three Tall Amount 2, 0.1, 0, 1)$,
    $float(Two Tall Amount 3, 0, 0, 1)$,
    $float(Three Tall Amount 3, 0, 0, 1)$,
    $float(Two Tall Amount 4, 0, 0, 1)$,
    $float(Three Tall Amount 4, 0, 0, 1)$,
    $float(Two Tall Amount 5, 0, 0, 1)$,
    $float(Three Tall Amount 5, 0, 0, 1)$,
    $float(Two Tall Amount 6, 0, 0, 1)$,
    $float(Three Tall Amount 6, 0, 0, 1)$
}

local noise_size = $int(Noise Size, 7, 1, 40)$ -- The default is 7; change this value
local random_factor = $float(Random Factor, 0.2, 0, 1)$ -- The default is 0.2; change this value
local replaceMode =  $boolean(Replace existing foliage,false)$ -- The default is false; change this value
local eraserMode =  $boolean(Toggle eraser mode,false)$

-- To add blocks treated as foliage, they must be added to the foliage table below. Only blocks 
-- in this list will be recognized as foliage if eraser mode or replace existing foliage is toggled.
-- The brush will also avoid placing anything on top of blocks contained in this list. The blocks 
-- used in the current palette (i.e., the ones set for Plant 1 - Plant 6) will always be added 
-- automatically to this list. Adding an excessive number of plants to this list may cause some lag 
-- when using the brush.
local foliageTable = {
    blocks.conquest.wild_shrub,
    blocks.conquest.tall_grass,
    blocks.conquest.lush_grass,
    blocks.conquest.grass,
    blocks.conquest.kentucky_bluegrass,
    blocks.conquest.common_meadow_grass
}

-- To exclude additional blocks where the brush should not place anything on top, 
-- add them to the following table:
local ignoreBlocksTable = {
    blocks.air,
    blocks.water
}

-- NOTE: If the sum of Plant 1 Amount - Plant 6 Amount is less than one, the remaining 
-- amount will be left unaltered by the brush. If the sum is more than one, the amounts 
-- will be normalized to maintain their relative proportions. The Two/Three-Tall Amounts 
-- will be normalized in the same way.

------------------------ End of explanation ------------------------

----------------- CUSTOM FUNCTIONS -----------------

-- Function to check if a value is contained in a table
local function contains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function that places grass with the correct "layers" property at coordinates (a, b, c). The function 
-- sets the "layers" property of the foliage to match the block beneath it. If the block below does not 
-- have a "layers" property, the condition getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, 
-- y - 1, z), "layers=n") will always evaluate to true, which is why it must be checked for "layers=8" first.
local function setGrass(a, b, c, grassType)
    for i = 8, 1, -1 do
        if getBlockState(a, b - 1, c) == withBlockProperty(getBlock(a, b - 1, c), "layers=" .. i) then
            local block = withBlockProperty(grassType, "layers=" .. i)
            setBlock(a, b, c, block)
            return 
        end
    end
    return nil
end

-- Sums the first n values of a table containing numbers
local function sum(table, n)
local sum = 0	
	for i=1, n do
		sum = sum + table[i]
	end
return sum
end

-- Given a table of numbers, this function calculates their sum and
-- normalizes them if the sum exceeds 1, keeping their ratios consistent.
local function normalize(table)
    local sum = sum(table,#table)

    if sum > 1 then
        for i, v in ipairs(table) do
            table[i] = v / sum
        end
    end
	return table
end

-- Define the noise grid used in the function below
local noise = getSimplexNoise(x/noise_size, y/noise_size, z/noise_size)

-- This function will be used a couple of times to actually place the grass based
-- on the set amounts.
function go(offset)
local randomVar = math.random() -- random variable for placing two/three tall grasses
	
	for i=1,6 do
		if noise < sum(plant_amounts_table,i) then
			plant = plant_table[i]
            -- Tall Grass needs special treatment
			if plant == withBlockProperty(blocks.conquest.tall_grass) then
                setGrass(x, y + offset, z, plant)
				local tall_grass_upper = withBlockProperty(blocks.conquest.tall_grass, "half=upper")
				setGrass(x, y + offset + 1, z, tall_grass_upper)
                return
			end

			if randomVar < two_three_tall_amounts_table[2 * i] then
				setGrass(x, y + offset, z, plant)
				setGrass(x, y + offset + 1, z, plant)
				setGrass(x, y + offset + 2, z, plant)
			elseif randomVar < two_three_tall_amounts_table[2 * i] + two_three_tall_amounts_table[2 * i - 1] then
				setGrass(x, y + offset, z, plant)
				setGrass(x, y + offset + 1, z, plant)
			else
				setGrass(x, y + offset, z, plant)
			end
			return
		end	
	end
	-- Return nil if no plant should be placed according to the noise
	return nil
end

-- Given a plant block at coordinates (a, b, c) contained in
-- foliageTable, this function returns the amount of plant blocks
-- (i.e., blocks contained in foliageTable) below (a, b, c), including
-- the block at (a, b, c) itself.
local function getPlantHeight(a,b,c)
	for i=1,5 do
		if not (contains(foliageTable, getBlock(a, b-i, c)) or contains(plant_table, withBlockProperty(getBlock(a, b-i, c)))) then
			return i
		end
	end
end

-- Returns a random number between min and max with a distribution 
-- defined by a distorted sigmoid function. Composing a uniformly 
-- distributed random variable taking values in [0, 1] with 
-- the inverse of a distribution function yields a new random 
-- variable that has the specified distribution. The function used 
-- in the return is simply the inverse of a distribution given by 
-- a distorted sigmoid function.
local function randomWithFancyDistribution(min,max)
	-- If random_factor > 0.7, 'b' scales down as random_factor increases 
	-- from 8 to nearly 0 at random_factor = 1. This shifts the distribution 
	-- toward uniformity, ensuring that at random_factor = 1, the result is 
	-- essentially fully random. Without this adjustment, the distribution 
	-- with b = 8 would not be fully random.
	local b = math.min(8, 27*(1.003 - random_factor))
	local c = 0.5
	local exp1 = math.exp(b/2)
	local exp2 = math.exp(-b/2)
	local a = (2 + exp1 + exp2) / (exp1 - exp2)
	local d = a / (1 + exp1)
	return (max - min) * (-(1/b) * math.log(a/(math.random() + d) - 1) + c) + min
end

--------------- ERASER MODE ---------------

if eraserMode == true then
	if contains(foliageTable, getBlock(x, y, z)) or contains(plant_table, withBlockProperty(getBlock(x, y, z))) then
		return blocks.air
	else
		return nil
	end
end

------------ ENSURE TARGET BLOCK IS VALID ------------

-- Ensure the target block is air before placing foliage
if getBlock(x, y, z) ~= blocks.air then
	return nil
end 

-- Ensure the block below is a valid block (i.e. not contained
-- in ignoreBlocksTable)
if contains(ignoreBlocksTable, getBlock(x, y-1, z)) then
    return nil
end

--------- NORMALIZE THE VARIOUS AMOUNTS ---------

-- If the sum of the Plant Amounts or the Two/Three Tall Amounts
-- exceeds 1, they are normalized to sum to 1 while keeping their
-- ratios consistent.
normalize(plant_amounts_table)

for i=1,6 do
	local normalized_amounts = normalize({two_three_tall_amounts_table[2*i - 1],two_three_tall_amounts_table[2*i]})
	two_three_tall_amounts_table[2*i - 1] = normalized_amounts[1]
	two_three_tall_amounts_table[2*i] = normalized_amounts[2]
end

------------ ACTUAL PLANT PLACEMENT ------------

-- Noise value is slighlty shifted according to the random_factor
noise = randomWithFancyDistribution(math.max(noise - random_factor,0), math.min(noise + random_factor,1))

if not (contains(foliageTable, getBlock(x, y-1, z)) or contains(plant_table, withBlockProperty(getBlock(x, y-1, z)))) then
	go(0)
elseif replaceMode == true and noise < sum(plant_amounts_table,6) then -- noise < sum(plant_amounts_table,6) ensures that exisitng plants are only removed where new ones will be placed
	local plantHeight = getPlantHeight(x, y-1, z)
	for i=1, plantHeight do
		setBlock(x, y-i, z, blocks.air)
	end
	go(-plantHeight)
else
	return nil
end

