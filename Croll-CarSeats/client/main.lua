local menuOpen = false
local menuVehicle = 0


local ALLOWED_UI_KEYS = {
    panelBackground = true,
    panelBorder = true,
    panelShadow = true,
    textPrimary = true,
    headerBorder = true,
    iconBackground = true,
    iconColor = true,
    iconHoverBackground = true,
    hintText = true,
    kbdBackground = true,
    kbdBorder = true,
    seatBackground = true,
    seatHoverBackground = true,
    seatHoverBorder = true,
    seatCurrentBorder = true,
    seatCurrentBackground = true,
    subText = true,
    footerBorder = true,
    refreshBorder = true,
    refreshBackground = true,
    refreshColor = true,
    refreshHoverBackground = true,
}

local function safeUiValue(v)
    if type(v) ~= 'string' then return nil end
    local s = v:match('^%s*(.-)%s*$') or ''
    if #s == 0 or #s > 128 then return nil end
    if s:find('[\n\r;{}<>]') then return nil end
    return s
end

local function nuiUiPayload()
    local src = Config.UI
    if type(src) ~= 'table' then return {} end
    local out = {}
    for key in pairs(ALLOWED_UI_KEYS) do
        local val = safeUiValue(src[key])
        if val then out[key] = val end
    end
    return out
end

--- Highest passenger seat index for this model (0..n). Driver is -1.
--- Uses model seat count so we do not list extra engine slots (e.g. index 3 on a 4-seat car).
local function getMaxPassengerIndex(vehicle)
    local n = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    if n < 1 then n = 1 end
    return math.max(-1, n - 2)
end

local function notify(msg, nType, duration)
    if lib and lib.notify then
        lib.notify({
            description = tostring(msg or ''),
            type = nType or 'inform',
            duration = duration or 4000,
        })
    end
end

local function nuiStrings()
    return {
        title = 'Seats',
        hintBefore = 'Choose a free seat. ',
        escKey = 'Esc',
        hintAfter = ' closes.',
        refresh = 'Refresh',
        closeAria = 'Close',
        statusHere = 'You are here',
        statusOccupied = 'Occupied',
        statusEmpty = 'Empty',
        seatFallback = 'Seat %s',
    }
end

local function sendOpenNui(seats)
    SendNUIMessage({
        action = 'open',
        seats = seats,
        ui = nuiUiPayload(),
        strings = nuiStrings(),
    })
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    menuVehicle = 0
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

---@param vehicle number
---@return table[] seats { index, label, free, current }
local function buildSeatPayload(vehicle)
    local ped = PlayerPedId()
    local maxPassengerIndex = getMaxPassengerIndex(vehicle)

    local currentSeat = nil
    for seat = -1, maxPassengerIndex do
        if GetPedInVehicleSeat(vehicle, seat) == ped then
            currentSeat = seat
            break
        end
    end

    local function labelFor(seatIndex)
        if seatIndex == -1 then return 'Driver' end
        if seatIndex == 0 then return 'Front passenger' end
        if seatIndex == 1 then return 'Rear left' end
        if seatIndex == 2 then return 'Rear right' end
        return ('Seat %d'):format(seatIndex + 2)
    end

    local seats = {}
    for seat = -1, maxPassengerIndex do
        local occupant = GetPedInVehicleSeat(vehicle, seat)
        local free = occupant == 0 or occupant == ped
        seats[#seats + 1] = {
            index = seat,
            label = labelFor(seat),
            free = free,
            current = seat == currentSeat,
        }
    end
    return seats
end

local function openMenu()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        notify('You must be inside a vehicle.', 'error')
        return
    end

    menuVehicle = vehicle
    menuOpen = true

    local seats = buildSeatPayload(vehicle)
    SetNuiFocus(true, true)
    sendOpenNui(seats)

    CreateThread(function()
        while menuOpen do
            Wait(200)
            if not menuOpen then break end
            local v = GetVehiclePedIsIn(PlayerPedId(), false)
            if v == 0 or v ~= menuVehicle then
                closeMenu()
                break
            end
        end
    end)
end

---@param seat number raw NUI/seat index
---@return integer?
local function asIntegerSeat(seat)
    if type(seat) ~= 'number' then return nil end
    if seat ~= seat then return nil end
    if seat == math.huge or seat == -math.huge then return nil end
    local ti = math.tointeger(seat)
    if ti ~= nil then return ti end
    local f = math.floor(seat)
    if math.abs(seat - f) > 1e-9 then return nil end
    return math.tointeger(f)
end

local function tryWarpToSeat(seatIndex)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or vehicle ~= menuVehicle then
        notify('You left the vehicle.', 'error')
        closeMenu()
        return
    end

    local maxPassengerIndex = getMaxPassengerIndex(vehicle)
    if seatIndex < -1 or seatIndex > maxPassengerIndex then
        notify('Invalid seat.', 'error')
        return
    end

    if not IsVehicleSeatFree(vehicle, seatIndex) and GetPedInVehicleSeat(vehicle, seatIndex) ~= ped then
        notify('That seat is occupied.', 'error')
        return
    end

    TaskWarpPedIntoVehicle(ped, vehicle, seatIndex)
    closeMenu()
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('selectSeat', function(data, cb)
    if not menuOpen or menuVehicle == 0 then
        cb('ok')
        return
    end
    local seat = data and data.seat
    local idx = asIntegerSeat(seat)
    if idx == nil then
        cb('ok')
        return
    end
    tryWarpToSeat(idx)
    cb('ok')
end)

RegisterNUICallback('refresh', function(_, cb)
    if not menuOpen or menuVehicle == 0 then
        cb('ok')
        return
    end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or vehicle ~= menuVehicle then
        closeMenu()
        cb('ok')
        return
    end
    local seats = buildSeatPayload(vehicle)
    sendOpenNui(seats)
    cb('ok')
end)

RegisterCommand('seatmenu', function()
    if menuOpen then
        closeMenu()
        return
    end
    openMenu()
end, false)

pcall(function()
    local desc = Config.CommandSuggestion
    if type(desc) ~= 'string' or desc == '' then
        desc = 'Open seat menu (when inside a vehicle)'
    end
    TriggerEvent('chat:addSuggestion', '/seatmenu', desc)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeMenu()
end)
