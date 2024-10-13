--------------------------------------------------------------------
---------------------- CONQUEST CROPS BRUSH -----------------------
--------------------------------------------------------------------

-- To save a preset you have to change the default values for the various parameters of the brush directly here in the code
-- The default value to change is always the first value (block id, number, boolean) after the name of the parameter shown in the UI

local crop = $blockState(Crop, conquest:wheat)$
local minAge = $int(Minimum Age, 0, 0, 7)$ -- The default is (the first) 0; change this value
local maxAge = $int(Maximum Age, 7, 0, 7)$ -- The default is (the first) 7; change this value
local cropAmount = $float(Crop Amount, 0.8, 0, 1)$ -- The default is 0.8; change this value
local noise_size = $int(Noise Size, 7, 1, 40)$ -- The default is 7; change this value
local random_factor = $float(Random Factor, 0.2, 0, 1)$ -- The default is 0.2; change this value
local replaceMode =  $boolean(Replace existing crops,false)$ -- The default is false; change this value
local eraserMode =  $boolean(Toggle eraser mode,false)$

-- To exclude additional blocks where the brush should not place anything on top, 
-- add them to the following table:
local ignoreBlocksTable = {
    blocks.air,
    blocks.water
}

-- NOTE: If the Crop Amount is less than one, the remaining amount will be left unaltered by the brush.

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

-- Function that places crops with the correct "layers" property at coordinates (a, b, c). The function 
-- sets the "layers" property of the foliage to match the block beneath it. If the block below does not 
-- have a "layers" property, the condition getBlockState(x, y - 1, z) == withBlockProperty(getBlock(x, 
-- y - 1, z), "layers=n") will always evaluate to true, which is why it must be checked for "layers=8" first.
local function setCrop(a, b, c, age)
    for i = 8, 1, -1 do
        if getBlockState(a, b - 1, c) == withBlockProperty(getBlock(a, b - 1, c), "layers=" .. i) then
            local block = withBlockProperty(crop, "layers=" .. i, "age=" .. age)
            setBlock(a, b, c, block)
            return 
        end
    end
    return nil
end

-- Define the noise grid used in the function below
local noise = getSimplexNoise(x/noise_size, y/noise_size, z/noise_size)

-- This function will be used a couple of times to actually place the crops based
-- on the set amounts.
local function go(offset)
    for i=maxAge, minAge, -1 do
        if noise < (maxAge - i + 1) * cropAmount/(maxAge - minAge + 1) then
            setCrop(x, y + offset, z, i)
            break
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
	if withBlockProperty(getBlock(x, y, z)) == crop then
		return blocks.air
	else
		return nil
	end
end

------------ ENSURE TARGET BLOCK IS VALID ------------

-- Ensure the target block is air before placing crops
if getBlock(x, y, z) ~= blocks.air then
	return nil
end 

-- Ensure the block below is a valid block (i.e. not contained
-- in ignoreBlocksTable)
if contains(ignoreBlocksTable, getBlock(x, y-1, z)) then
    return nil
end

-- Noise value is slighlty shifted according to the random_factor
noise = randomWithFancyDistribution(math.max(noise - random_factor,0), math.min(noise + random_factor,1))

if withBlockProperty(getBlock(x, y-1, z)) ~= crop then
    go(0)
elseif replaceMode == true then
    go(-1)
else
    return nil
end