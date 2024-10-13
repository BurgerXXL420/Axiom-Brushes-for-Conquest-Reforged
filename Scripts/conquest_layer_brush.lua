--------------------------------------------------------------------
-------------------- CONQUEST LAYERS BRUSH --------------------
--------------------------------------------------------------------

-- To save a preset you have to change the default values for the various parameters of the brush directly here in the code
-- The default value to change is always the first value (block id, number, boolean) after the name of the parameter shown in the UI

local blocks_table = {
    $blockState(Block1, minecraft:red_wool)$,
    $blockState(Block2, minecraft:purple_wool)$,
    $blockState(Block3, minecraft:blue_wool)$,
    $blockState(Block4, minecraft:green_wool)$,
    $blockState(Block5, minecraft:yellow_wool)$,
    $blockState(Block6, minecraft:orange_wool)$,
    $blockState(Block7, minecraft:black_wool)$,
    $blockState(Block8, minecraft:white_wool)$,
    $blockState(Block9, minecraft:gray_wool)$
}

local layers_table = {
    $blockState(Layer1, conquest:red_wool_slab)$,
    $blockState(Layer2, conquest:purple_wool_slab)$,
    $blockState(Layer3, conquest:blue_wool_slab)$,
    $blockState(Layer4, conquest:green_wool_slab)$,
    $blockState(Layer5, conquest:yellow_wool_slab)$,
    $blockState(Layer6, conquest:orange_wool_slab)$,
    $blockState(Layer7, conquest:black_wool_slab)$,
    $blockState(Layer8, conquest:white_wool_slab)$,
    $blockState(Layer9, conquest:gray_wool_slab)$
}

local blocks_amounts_table = {
    $float(Block1 Amount, 0.5, 0, 1)$, -- The default is 0.5; change this value
    $float(Block2 Amount, 0.5, 0, 1)$,
    $float(Block3 Amount, 0.5, 0, 1)$,
    $float(Block4 Amount, 0.5, 0, 1)$,
    $float(Block5 Amount, 0.5, 0, 1)$,
    $float(Block6 Amount, 0.5, 0, 1)$,
    $float(Block7 Amount, 0.5, 0, 1)$,
    $float(Block8 Amount, 0.5, 0, 1)$,
    $float(Block9 Amount, 0.5, 0, 1)$
}

local noise_size = $int(Noise Size, 10, 1, 40)$ -- The default is 10; change this value
local random_factor = $float(Random Factor, 0.2, 0, 1)$ -- The default is 0.2; change this value

-- If the sum of Block1 Amount - Block9 Amount is less than one, 
-- the remaining area will be left unaltered by the brush. If the 
-- sum is more than one, the amounts will be normalized to maintain 
-- their relative proportions.

------------------------ End of explanation ------------------------

----------------- CUSTOM FUNCTIONS -----------------

-- Sums the first n values of a table containing numbers
function sum(table, n)
    local sum = 0	
        for i = 1, n do
            sum = sum + table[i]
        end
    return sum
end
    
-- Given a table of numbers, this function calculates their sum and
-- normalizes them if the sum exceeds 1, keeping their ratios consistent.
function normalize(table)
    local sum = sum(table,#table)
    
    if sum > 1 then
        for i, v in ipairs(table) do
            table[i] = v / sum
        end
    end
    return table
end

-- Function to replace an existing layered block at coordinates 
-- a, b, c with the correct layered block given by the argument "layerType"
function setLayer(a, b, c, layerType)
    for i = 1, 8 do
        if getBlockState(x, y, z) == withBlockProperty(getBlock(x, y, z), "layers=" .. i) then
            local layer = withBlockProperty(layerType, "layers=" .. i)
            setBlock(a, b, c, layer)
            return 
        end
    end
    return nil
end

-- Checks if the Block at coordinates a,b,c has the "layers" property
function isLayeredBlock(a,b,c)
	return getBlockProperty(getBlock(a,b,c),"layers") ~= nil
end

-- Returns a random number between min and max with a distribution 
-- defined by a distorted sigmoid function. Composing a uniformly 
-- distributed random variable taking values in [0, 1] with 
-- the inverse of a distribution function yields a new random 
-- variable that has the specified distribution. The function used 
-- in the return is simply the inverse of a distribution given by 
-- a distorted sigmoid function.
function randomWithFancyDistribution(min,max)
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

------------ ENSURE TARGET BLOCK IS VALID ------------

-- Only select blocks which are on the surface
if getBlock(x,y,z) == blocks.air or getBlock(x,y+1,z) ~= blocks.air then
	return nil
end

--------- NORMALIZE THE BLOCK AMOUNTS ---------

-- If the sum of the Block Amounts exceeds 1, they are normalized 
-- to 1 while keeping their ratios consistent.
normalize(blocks_amounts_table)

------------ ACTUAL LAYER  PLACEMENT ------------

local noise = getSimplexNoise(x/noise_size, y/noise_size, z/noise_size)
-- Noise value is slighlty shifted according to the random_factor
noise = randomWithFancyDistribution(math.max(noise - random_factor,0), math.min(noise + random_factor,1))

for i = 1, 9 do
    if noise < sum(blocks_amounts_table,i) then -- Check which block to place according to (distorted) noise value
        -- Replace the first three blocks below the surface with the according block 
        for j = 1, 3 do
            setBlock(x, y-j, z, blocks_table[i])
        end
        -- Replace the surface block
        if isLayeredBlock(x, y, z) then
            setLayer(x, y, z, layers_table[i])
        else
            setBlock(x, y, z, blocks_table[i])
        end
        return nil
    end
end

-- Return nil if no blocks should be replaced
return nil

