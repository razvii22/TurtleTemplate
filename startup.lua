-- Initialize Rednet
rednet.open("left")

local function reply(message,...)
    local body = {...}
    local reply = ""
    for k,v in pairs(body) do
        if tostring(v) then
            reply = reply.." "..tostring(v)
        end
    end
    print(reply)
    -- rednet.send(message[1],{...},message[3])
end

local commandVerbs = {
    "run",
    "stop",
}

local function match(table,item)
    for k,v in pairs(table) do
        if item == v then return true end
    end
    return false
end


-- Variable to store the active coroutine
local activeCoroutine = nil

-- Function to handle commands
local function handleCommand(message)

    assert(type(message) == "table","Invalid message format")
    assert(type(message[2]) == "table","Invalid message format")
    assert(type(message[2].verb) == "string" and match(commandVerbs,message[2].verb),"Invalid command verb")
    message[2].command = message[2].command or ""
    local verb = message[2].verb
    local command = {}
    for w in message[2].command:gmatch("%S+") do table.insert(command,w) end

    if verb == "run" then
        assert(command[1],"No argument provided")
        if activeCoroutine then
            reply(message,"A program is already running. Stop it first.")
            return
        end

        local programName = assert(shell.resolveProgram(command[1]),"No such program.")
        local program = assert(loadfile(programName))
        local co = coroutine.create(function()
            program(table.unpack(command,2))
        end)
        activeCoroutine = co
    elseif verb == "stop" then
        if activeCoroutine then
            activeCoroutine = nil
            print("Program stopped.")
        else
            print("No active program to stop.")
        end
    end
end

-- Function to listen for rednet messages
local function listenForCommands()
    while true do
        local message = {rednet.receive("Miner")}
        if message then
            reply(message,pcall(handleCommand,message))
        end
    end
end

-- Function to manage and resume the active coroutine
local function manageCoroutine()
    local eventData = {n=0}
    while true do
        local success = {}
        if activeCoroutine and coroutine.status(activeCoroutine) == "suspended" then
            success = {coroutine.resume(activeCoroutine,table.unpack(eventData,1,eventData.n))}
            if not success[1] then
                print("Error: " .. success[2])
                activeCoroutine = nil
            elseif coroutine.status(activeCoroutine) == "dead" then
                local label = os.getComputerLabel() or ("ID# "..os.getComputerID())
                print("Turtle "..label.." has finished its task or the program quit.")
                activeCoroutine = nil
            end
        end
        eventData = table.pack(os.pullEventRaw())
    end
end

-- Run both functions in parallel
parallel.waitForAny(listenForCommands, manageCoroutine)
