--[[ Mines a contiguous aggregation of
resource blocks. Meant for trees or 
veins of ore.
1  Place the turtle so it faces the 
   material you want.
2  Refuel the turtle if applicable.
3  Run this script.  
3a Note, if you want it to dig *all* 
   blocks around any matching one, to 
   give the spaces a neater 
   appearance, use 'a' as an argument.
   For example, if the script is 
   called vMiner: 
   vMiner a
3b Even neater but using more time 
   and more fuel: To dig out the whole
   rectangular prism surrounding the 
   vein, use 'r' argument:
   vMiner r

Copyright (c) 2015 - 2016
Robert David Alkire II, IGN ian_xw
Distributed under the MIT License.
(See accompanying file LICENSE or copy
at http://opensource.org/licenses/MIT)
]]

--- assigns fake/real turtle
--  toggle turtle before deployment
--  TODO remember deploy-time toggle
t = turtle
-- t = require "mockTurtle"

Locus = {}
Locus.__index = Locus
Locus.x = 0
Locus.y = 0
Locus.z = 0
--- A constructor which sets the 
-- current location
Locus.new= function( x, y, z )
  local self = setmetatable({}, Locus)
  self.x = x
  self.y = y
  self.z = z
  return self
end

local deadReckoner = {}
local dr = deadReckoner

--- relative to turtle heading at start 
deadReckoner.FORE = 0
deadReckoner.STARBOARD = 1
deadReckoner.AFT = 2
deadReckoner.PORT = 3
deadReckoner.WAYS = {}
dr.WAYS[deadReckoner.FORE] = "FORE"
dr.WAYS[deadReckoner.STARBOARD]= 
    "STARBOARD"
dr.WAYS[deadReckoner.AFT] = "AFT"
dr.WAYS[deadReckoner.PORT] = "PORT"
  
deadReckoner.heading=deadReckoner.FORE

--- Current position relative to start
deadReckoner.place= Locus.new(0, 0, 0)

--- Maximum x, y, z relative to start,
-- located or dug
deadReckoner.placeMAX=Locus.new(0,0,0)

--- Minimum x, y, z relative to start,
-- located or dug
deadReckoner.placeMIN=Locus.new(0,0,0)

--- forward regardless of heading
deadReckoner.AHEAD = 4
deadReckoner.UP = 5
deadReckoner.DOWN = 6

--- Turns as needed to face the 
-- target direction indicated
-- @param target must be dr.FORE, 
-- dr.STARBOARD, dr.AFT, or dr.PORT
deadReckoner.bearTo= function(target)

  local trnsRght = 
      target - deadReckoner.heading
  
  local trns = math.abs( trnsRght )
  if trns ~= 0 then
    
    if trns== 3 then
      trns= 1
      trnsRght= trnsRght/-3
    end
    
    local i = 0
    while i < trns do
      if trnsRght >= 0 then
        t.turnRight()
      else
        t.turnLeft()
      end -- which way
      i = i + 1
    end -- turn loop
  end -- there were any turns
  
  deadReckoner.heading = target
end

--- If way is fore, starboard, aft or
-- port, then bear to that direction
-- @param way can any of the heading
-- constants: FORE, STARBOARD, AFT,
-- PORT, UP, DOWN or even AHEAD
-- @return way is AHEAD if the param 
-- had been a horizontal direction 
-- (FORE, AFT, PORT, STARBOARD). 
-- Otherwise it's the same as the input
-- param.
deadReckoner.correctHeading=
    function(way)
    
  if way < 4 then
    dr.bearTo( way )
    way = dr.AHEAD
  end
  
  return way
  
end

--- Adjusts placeMAX and placeMIN as
-- applicable.
deadReckoner.setMaxMin=function(x,y,z)

  if x > dr.placeMAX.x then
    dr.placeMAX.x = x
  elseif x < dr.placeMIN.x then
    dr.placeMIN.x = x
  end
  
  if y > dr.placeMAX.y then
    dr.placeMAX.y = y
  elseif y < dr.placeMIN.y then
    dr.placeMIN.y = y
  end
  
  if z > dr.placeMAX.z then
    dr.placeMAX.z = z
  elseif z < dr.placeMIN.z then
    dr.placeMIN.z = z
  end
  
end

--- Gets the coordinates of the block
-- currently next to the turtle,
-- depending on which way one would
-- look.
-- @param way must be deadReckoner's 
-- (dr's) AFT, FORE, PORT, STARBOARD,
-- UP, DOWN or AHEAD.
-- @return x, y, z coordinates of the 
-- adjacent block.
deadReckoner.getTargetCoords=
    function(way)
  
  local ix = dr.place.x
  local iy = dr.place.y
  local iz = dr.place.z
  
  if way == dr.AHEAD then
    way = dr.heading
  end
  
  if way== dr.AFT then
    iz= iz - 1
  elseif way== dr.FORE then
    iz= iz + 1
  elseif way== dr.PORT then
    ix= ix- 1
  elseif way== dr.STARBOARD then
    ix= ix+ 1
  elseif way== dr.UP then
    iy= iy + 1
  elseif way== dr.DOWN then
    iy= iy - 1
  end
  
  return ix, iy, iz
  
end


--- Finds the distance between the
-- current location and some other
-- place, without diagonal travel
-- @param x, y, z are the coords of
-- the other place
-- @return the distance
deadReckoner.howFarFrom=function(x,y,z)
  local dx= math.abs( dr.place.x- x )
  local dy= math.abs( dr.place.y- y )
  local dz= math.abs( dr.place.z- z )
  return dx + dy + dz
end

--- Calculates distance from starting
-- place, considering that turtles
-- do not move diagonally in their 
-- present form.
-- @return number of moves to get back
deadReckoner.howFarFromHome=function()
  return math.abs(dr.place.x)+ 
      math.abs(dr.place.y)+ 
      math.abs(dr.place.z)
end

--- Inspects the given direction, and
-- also calls to evaluate the target
-- block for max and min coords.
-- @param way FORE, UP, AHEAD etc
-- @return boolean success, table 
-- data/string error message
deadReckoner.inspect= function(way)

  way = dr.correctHeading(way)
  local ok, item
  if way== dr.AHEAD then
    ok, item= t.inspect()
  elseif way== dr.UP then
    ok, item= t.inspectUp()
  else
    ok, item= t.inspectDown()
  end
  
  local ix, iy, iz = 
      dr.getTargetCoords(way)
  
  dr.setMaxMin(ix, iy, iz)
  return ok, item
end

--- Digs.
-- @param way must be dr.FORE, 
-- dr.STARBOARD, dr.FORE, dr.AFT
-- dr.AHEAD, dr.UP or dr.DOWN
-- @return isAble true if it really 
-- was able to dig
-- @return whyNot if isAble, nil. Else,
-- reason why not.
deadReckoner.dig= function( way )

  way = dr.correctHeading( way )
  
  local dug= false
  local whyNot
  if way== dr.AHEAD then
    dug, whyNot= t.dig()
  elseif way== dr.UP then
    dug, whyNot= t.digUp()
  elseif way== dr.DOWN then
    dug, whyNot= t.digDown()
  end
  
  return dug, whyNot
end

--- Tries to move ahead, up or down. 
-- If successful,
-- it updates its current location
-- relative to where it started and 
-- returns true.
-- Else, it returns false and the
-- reason why not.
-- @param way is either dr.AHEAD, dr.UP 
-- or dr.DOWN, where dr is deadReckoner
deadReckoner.move= function( way )
  
  -- where way is dr.AHEAD, UP or DOWN
  local isAble, whynot
  if way== dr.AHEAD then
    isAble, whynot = t.forward()
    
    if isAble then
      if dr.heading== dr.AFT then
        dr.place.z= dr.place.z - 1
      elseif dr.heading== dr.FORE then
        dr.place.z= dr.place.z + 1
      elseif dr.heading== dr.PORT then
        dr.place.x= dr.place.x- 1
      else
        dr.place.x= dr.place.x+ 1
      end
      
    end -- isAble
  elseif way== dr.UP then
    isAble, whynot = t.up()
    if isAble then
      dr.place.y = dr.place.y + 1
    end
  elseif way== dr.DOWN then
    isAble, whynot = t.down()
    if isAble then
      dr.place.y = dr.place.y - 1
    end
  end -- AHEAD, UP or DOWN
  
  if isAble then
    dr.setMaxMin( dr.place.x, 
        dr.place.y, dr.place.z )
  end
  
  return isAble, whynot
end

--- Comparing destination with current
-- location, this finds the dominant
-- direction and distance in that
-- direction. X - Z plane gets
-- priority.
-- @param dest destination coordinates
-- @return direction: up, down, fore, 
-- aft, port or starboard
-- @return distance
deadReckoner.furthestWay = 
    function(dest)
  
  -- Dest - Current: +Srbrd -Port
  local direction = 0
  local dist = dest.x - dr.place.x
  if dist >= 0 then
    direction= dr.STARBOARD
  else
    direction= dr.PORT
  end
  
  -- Find Z diff +fore -aft
  local zDist = dest.z - dr.place.z
  if math.abs(zDist)>math.abs(dist)then
    dist= zDist
    if dist >= 0 then
      direction= dr.FORE
    else
      direction= dr.AFT
    end
  end
  
  -- Y:  +up -down
  local yDist = dest.y - dr.place.y
  if math.abs(yDist)>math.abs(dist)then
    dist= yDist
    if dist >= 0 then
      direction= dr.UP
    else
      direction= dr.DOWN
    end
  end
  
  return direction, math.abs(dist)
  
end

local veinMiner = {}
local vm = veinMiner

--- For estimating fuel need
veinMiner.MOVESPERCUBE = 15

--- If part of larger task, from caller
veinMiner.previousDistance = 0

--- The kind of block it's looking for
veinMiner.targetBlockName = ""

--- Defines cube's surrounding loci, in
  -- the order in which they are to
  -- be inspected.
veinMiner.cubeInspectionSequence = {
  {0, 1, 0}, {0, -1, 0}, {0, 0, 1},
  {0, 1, 1}, {0, -1, 1}, {1, 0, 1},
  {1, 1, 1}, {1, -1, 1}, {1, 0, 0},
  -- 10
  {1, 1, 0}, {1, -1, 0}, {1, 0,-1},
  {1, 1,-1}, {1, -1,-1}, {0, 0,-1},
  {0, 1,-1}, {0, -1,-1}, {-1,0,-1},
  -- 19
  {-1,1,-1}, {-1,-1,-1}, {-1,0, 0},
  {-1, 1,0}, {-1,-1, 0}, {-1,0, 1},
  {-1, 1,1}, {-1,-1, 1}
}

--- Collection of "cubes", which are
-- spaces to explore, defined by 
-- central locations.
veinMiner.cubeStack = {}

--- Array of locations which have been
-- inspected.
veinMiner.inspected = {}

--- Count of blocks that have been
-- marked as inspected
veinMiner.inspectedCount= 0

--- Count of inspections skipped due
-- to logic with the Check function
-- (when the turtle was right next to
-- it)
veinMiner.inspectedSkipped= 0

--- Count of times that coordinates
-- to goLookAt were actually for the
-- robot's own location
veinMiner.inspectSelfAvoidance = 0

--- If true, then the miner is supposed
-- to *dig* all the blocks from around
-- the target block, even the ones that
-- don't match the target blocks.
veinMiner.isAll = false

--- Count of goLookAt calls skipped due
-- to logic within inspectACube,
-- therefore avoiding extra movements
veinMiner.goLookSkipped= 0

--- Records a location as having been
-- inspected
veinMiner.setInspected=function(x,y,z)
  vm.inspected[
      string.format("%d,%d,%d",x,y,z)]= 
      true
  vm.inspectedCount=vm.inspectedCount+1 
end

veinMiner.isInspected=function(x,y,z)
  local indx= string.format(
      "%d,%d,%d", x, y, z )
  local val= vm.inspected[indx]
  local isInspctd = not ( val == nil )
  return isInspctd
end

--- Determines whether the mining/
-- felling task is complete.
veinMiner.isVeinExplored= function()
  local isExplored = false
  local cubeCount= 
      table.maxn(vm.cubeStack)
  if cubeCount== 0 then
    isExplored = true
    print("Vein is explored")
--  else
--    print( "unexplored cubeCount: ".. 
--        cubeCount )
  end
  
  return isExplored
end

--- If there's enough fuel to explore
-- one last cube and move back to the
-- original place.
veinMiner.isFuelOK4Cube = function()
  local isOK = false
  local fuel = t.getFuelLevel()
  if fuel == "unlimited" then
    isOK = true
  else
    local fuelNeed = 
        veinMiner.previousDistance +
        dr.howFarFromHome() +
        vm.MOVESPERCUBE
    if fuel > fuelNeed then
      isOK = true
    else
      print("Fuel too low: ".. fuel )
    end
  end
  return isOK
end

--- See's if there's enough fuel to get
-- to the destination then get home
-- @param x, y, z coords for dstnation
-- @return true if fuel OK or unlimited
veinMiner.isFuelOK4Dest= 
    function(x, y, z) 
  local isOK = false
  local fuel = t.getFuelLevel()
  if fuel == "unlimited" then
    isOK = true
  else
    local destToHome = math.abs(x)+
        math.abs(y)+ math.abs(z)
    local fuelNeed =
        dr.howFarFrom(x,y,z)+
        destToHome+ vm.previousDistance
    if fuel >= fuelNeed then
      isOK = true
    else
      print("Not enough fuel:".. fuel)
    end
  end
  return isOK
end

--- If the target has not already been 
-- inspected it gets checked here.
-- If so it gets added to the inspected
-- array, to avoid redundancy.
-- If inspection shows block is wanted,
-- its location gets added to the 
-- cubeStack
-- @param way is must be dr.FORE, 
-- dr.STARBOARD, dr.FORE, dr.AFT
-- dr.AHEAD, dr.UP or dr.DOWN
-- @return true if target block matches
-- what was wanted.
veinMiner.check= function(way)
  local isWanted = false

  local ix = 0
  local iy = 0
  local iz = 0
  ix, iy, iz= dr.getTargetCoords(way)
  
  way = dr.correctHeading(way)
  
  -- If it still needs to be inspected,
  if vm.isInspected(ix,iy,iz) then
    vm.inspectedSkipped = 
        vm.inspectedSkipped + 1
  else
    local ok, item
    ok, item= dr.inspect(way)
    
    if ok then
      if item.name==vm.targetBlockName 
          then
        isWanted = true
        local locus= Locus.new( ix, 
            iy, iz)
        table.insert( vm.cubeStack, 
            locus)
      end -- match
    end -- ok
    
    -- adds to the inspected array.
    vm.setInspected(ix, iy, iz )
  end

  return isWanted
end

--- Moves, checks, and pushes to stack
-- when applicable.
-- @param way is either dr.AHEAD, 
-- STARBOARD, PORT, FORE, or AFT 
-- dr.UP, or dr.DOWN where dr is 
-- deadReckoner
-- @param moves
-- @return isAble true if it really was
-- able to move and dig.
-- @return whyNot if isAble, nil. Else,
-- reason why not.
veinMiner.explore= function(way, moves)
  
  way = dr.correctHeading(way)
  
  local isAble, whynot
  
  for i = 1, moves do
    isAble, whynot = dr.move(way)
    
    -- if cannot, because obstructed
    if not isAble then
    
      if whynot=="Movement obstructed"
          then
        vm.check( way )
        isAble, whynot = dr.dig( way )
        isAble, whynot= dr.move( way )
      else
        print( "Stuck. ".. whynot )
      end
      
    end
    
  end -- end moves loop
  
  return isAble, whynot
end

--- Moves starboard or port 
-- depending on where dest is compared 
-- to the robot's current location.  
-- Inspects and/or breaks when needed.
-- @param dest a target location on
-- the same x/z plane
veinMiner.exploreToX= function( dest )

  local diff = dest.x - dr.place.x
  local moves = math.abs(diff)
  local way = 0
  if diff > 0 then
    way = dr.STARBOARD
  elseif diff < 0 then
    way = dr.PORT
  end
  
  vm.explore( way, moves)
  
end

--- Up or down
veinMiner.exploreToY= function( dest )

  local diff = dest.y - dr.place.y
  local moves = math.abs(diff)
  local way = 0
  if diff > 0 then
    way = dr.UP
  elseif diff < 0 then
    way = dr.DOWN
  end
  
  vm.explore( way, moves)
  
end

--- Fore or aft
veinMiner.exploreToZ= function( dest )
  local diff = dest.z - dr.place.z
  local moves = math.abs(diff)
  local way = 0
  if diff > 0 then
    way = dr.FORE
  elseif diff < 0 then
    way = dr.AFT
  end
  
  vm.explore( way, moves)
end

--- Moves to the location, inspecting,
-- pushing and breaking when needed
-- @param place is location relative
-- to turtle's original location
veinMiner.exploreTo= function( place )
  vm.exploreToX( place )
  vm.exploreToZ( place )
  vm.exploreToY( place )
end

--- Inspects block at the given 
-- coordinates, moving if needed.
-- Pushes matching loci via check()
-- Digs matching loci via dig()
veinMiner.goLookAt= function(x, y, z)
  
  local dest = {x, y, z}
  
  local diffs= {x- dr.place.x,
                y- dr.place.y,
                z- dr.place.z }

  -- count of non-zero dimensions
  local nzCount= 0
  for i = 1, 3 do
    if diffs[i] ~= 0 then
      nzCount= nzCount+ 1
    end
  end
  
  local direction = 0
  local dist = 0
  local dest = Locus.new(x,y,z)
  
  -- All three coordinates differ
  if nzCount > 2 then
    -- Explore the farthest way
    direction, dist= 
        dr.furthestWay(dest)
    vm.explore(direction, dist)    
  end
  
  -- Two or three coords were different
  if nzCount > 1 then
    -- Explore (what is now) the 
    -- farthest way
    direction, dist= 
        dr.furthestWay(dest)
    vm.explore(direction, dist)
  end
  
  -- Unless it's to inspect self
  if nzCount > 0 then
    -- Explore *Up To* dest, farthest
    direction, dist= 
        dr.furthestWay(dest)
    dist = dist - 1
    vm.explore(direction, dist)
    -- Check it
    if direction <= dr.PORT then
      direction= dr.AHEAD
    end
    if vm.check(direction) or 
        vm.isAll then
      dr.dig(direction)
    end
  else -- Coords were turtle's place
    vm.inspectSelfAvoidance= 
        vm.inspectSelfAvoidance + 1
    vm.setInspected(x,y,z)
  end
  
end

--- Pulls a location from the stack,
-- inspects it surrounding blocks. Each
-- matching location gets added to the
-- stack.
veinMiner.inspectACube= function()
  
  -- Pops one
  local cube=table.remove(vm.cubeStack)
  
  -- shorthand
  local cis= vm.cubeInspectionSequence
  
  -- For each surrounding locus sl
  local maxOfSequence = table.maxn( 
      vm.cubeInspectionSequence ) 
  for sl= 1, maxOfSequence do
    local x= cube.x + cis[sl][1]
    local y= cube.y + cis[sl][2]
    local z= cube.z + cis[sl][3]
    -- If not already inspected
    if vm.isInspected(x,y,z) then
      vm.inspectedSkipped = 
          vm.inspectedSkipped + 1
      vm.goLookSkipped = 
          vm.goLookSkipped + 1
    else
      vm.goLookAt( x, y, z )
    end -- if not inspected
  end
end

--- Sees if there's enough space in
-- the inventory for another cube
-- of target material
veinMiner.isInvtrySpaceAvail=function()
  
  local isAvail = false
  local frSpace = 0
  for i = 1, 16 do
    local itmCount = t.getItemCount(i)
    
    if itmCount == 0 then
      frSpace= frSpace+ 64
    else
      local slName= 
          t.getItemDetail(i).name
          
      if slName==
          vm.targetBlockName then
        frSpace= frSpace+ 64- itmCount
      end -- match
      
    end -- count zero-else
    
  end -- inventory loop
  
  -- Assuming a cube could be no more
  -- than 25 blocks, realistically
  if frSpace >= 25 then
    isAvail = true
  else
    print( "There might not be ".. 
    "enough inventory \nspace to ".. 
    "hold the target material" )
  end
  return isAvail
end

--- Digs out the remaining blocks
-- between the minimum, maximum 
-- coordinates so far
veinMiner.clearRectangle= function()

  local fulOK = true
  local tx = dr.placeMIN.x
  while tx<= dr.placeMAX.x and fulOK do
    local ty = dr.placeMIN.y
    while ty<= dr.placeMAX.y and 
        fulOK do
      local tz = dr.placeMIN.z
      while tz<= dr.placeMAX.z and
          fulOK do
        
        if not vm.isInspected(tx,ty,tz) 
            then
          fulOK= vm.isFuelOK4Dest(
              tx,ty,tz )
          if fulOK then
            vm.exploreTo(
                Locus.new(tx, ty, tz))
          end
        end
        
        tz = tz + 1 
      end
      ty = ty + 1
    end
    tx = tx + 1
  end
  
end

--- The main function: Inspects the 
-- block in front of it and sets its
-- name of that as the target material,
-- then mines for that until the vein
-- has been explored, the fuel is gone
-- or there isn't any more room.
veinMiner.mine= function( args )

  local isRectangle = false
  local isArgOK = true
  if table.getn( args ) > 0 then
    if args[1] == "a" then
      vm.isAll = true
    elseif args[1] == "r" then
      vm.isAll = true
      isRectangle = true
    else
      print( "Unknown argument: \"" ..
        args[1] .. "\". \n"..
        "Acceptable arguments are "..
        "a or r.  \n"..
        "Edit script for details." )
      isArgOK = false
    end
  end
  
  local isBlockOK = false
  local block = {}
  
  isBlockOK, block = 
      dr.inspect( dr.AHEAD )
  
  if isBlockOK and isArgOK then
    
    veinMiner.targetBlockName = 
        block.name
    print("target block: ".. 
        block.name)
    
    vm.check( dr.AHEAD )
    
    while vm.isFuelOK4Cube() and
        vm.isInvtrySpaceAvail() and 
        (not vm.isVeinExplored()) do
      vm.inspectACube()
    end
    
    if isRectangle then
      vm.clearRectangle()
    end
    
    -- Comes back and faces forward
    vm.exploreTo( Locus.new(0,0,0) )
    dr.bearTo( dr.FORE )
    
    print( "inspected count: ".. 
        vm.inspectedCount )
    print( "inspections skipped: "..
        vm.inspectedSkipped )
    print( "goLookAt calls skipped: ".. 
        vm.goLookSkipped )
    print( "inspect-self avoidance: "..
        vm.inspectSelfAvoidance )
    
    -- Possibly more found on way back
    -- If so, report it.
    local cubesYet= 
        table.maxn(vm.cubeStack)
    if cubesYet > 0 then
      print( "There are still ".. 
          cubesYet.. 
          " cubes to be explored." )
    end
  elseif not isBlockOK then
    print( "To start, there must \n"..
        "be a block of interest \n"..
        "in front of the turtle." )
  end
end

vm.mine({...})