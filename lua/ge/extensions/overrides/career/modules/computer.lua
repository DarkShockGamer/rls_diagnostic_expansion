-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

-- FIX: Ensure computer loads after inventory to break cycle
M.dependencies = {"career_career", "career_modules_inventory"}

local computerTetherRangeSphere = 4
local computerTetherRangeBox = 1
local tether

local computerFunctions
local computerId
local computerFacilityName
local menuData = {}

-- Used to help general diagnostics button get correct id from UI
M._pendingDiagnosticsInventoryId = nil

local reopenInProgress = false
local function reopenMenu()
  print("[computer.lua] reopenMenu() called - DISABLED to prevent automatic refresh loops")
  return
end

local function openMenu(computerFacility, resetActiveVehicleIndex, activityElement)
  print("[computer.lua] openMenu() called for facility: " .. tostring(computerFacility and computerFacility.id or "nil"))
  computerFunctions = {general = {}, vehicleSpecific = {}}
  computerId = computerFacility.id
  computerFacilityName = computerFacility.name

  menuData = {vehiclesInGarage = {}, resetActiveVehicleIndex = resetActiveVehicleIndex}
  local inventoryIds = career_modules_inventory.getInventoryIdsInClosestGarage()
  for _, inventoryId in ipairs(inventoryIds) do
    local vehicleData = {}
    vehicleData.inventoryId = inventoryId
    vehicleData.needsRepair = career_modules_insurance_insurance.inventoryVehNeedsRepair(inventoryId) or nil
    local vehicleInfo = career_modules_inventory.getVehicles()[inventoryId]
    vehicleData.vehicleName = vehicleInfo and vehicleInfo.niceName
    vehicleData.dirtyDate = vehicleInfo and vehicleInfo.dirtyDate
    table.insert(menuData.vehiclesInGarage, vehicleData)
    computerFunctions.vehicleSpecific[inventoryId] = computerFunctions.vehicleSpecific[inventoryId] or {}

    -- Per-vehicle diagnostics button
    computerFunctions.vehicleSpecific[inventoryId]["diagnostics"] = {
      id = "diagnostics",
      label = "Diagnostics Report",
      icon = "clipboard",
      order = 60,
      callback = function(computerId)
        guihooks.trigger("ChangeState", {state = "diagnostics-menu", params = {vehicleId = inventoryId}})
      end
    }
  end

  -- Active/top vehicle diagnostics button
  computerFunctions.general["diagnosticsActiveVehicle"] = {
    id = "diagnosticsActiveVehicle",
    label = "Diagnostics Report",
    icon = "clipboard",
    order = 60,
    callback = function(computerId)
      local vehicleId = M._pendingDiagnosticsInventoryId
      if not vehicleId and menuData.vehiclesInGarage and #menuData.vehiclesInGarage >= 1 then
        vehicleId = menuData.vehiclesInGarage[1].inventoryId
      end
      guihooks.trigger("ChangeState", {state = "diagnostics-menu", params = {vehicleId = vehicleId}})
      M._pendingDiagnosticsInventoryId = nil
    end
  }

  menuData.computerFacility = computerFacility
  if not career_modules_linearTutorial.getTutorialFlag("partShoppingComplete") then
    menuData.tutorialPartShoppingActive = true
  elseif not career_modules_linearTutorial.getTutorialFlag("tuningComplete") then
    menuData.tutorialTuningActive = true
  end

  extensions.hook("onComputerAddFunctions", menuData, computerFunctions)

  computerFunctions.general["workersManagement"] = {
    id = "workersManagement",
    label = "Workers",
    icon = "briefcase",
    order = 210,
    callback = function()
      local aiWorkerPage = require("career/modules/aiWorkerComputerPage")
      aiWorkerPage.openAIWorkerPage(computerId)
    end
  }

  local computerPos = freeroam_facilities.getAverageDoorPositionForFacility(computerFacility)
  local door = computerFacility.doors and computerFacility.doors[1]
  tether = nil
  if door then
    tether = career_modules_tether.startDoorTether(door, computerTetherRangeBox, M.closeMenu)
  end
  if not tether and computerPos then
    tether = career_modules_tether.startSphereTether(computerPos, computerTetherRangeSphere, M.closeMenu)
  end

  guihooks.trigger('ChangeState', {state = 'computer'})
  extensions.hook("onComputerMenuOpened")
end

-- Enhanced: support diagnosticsActiveVehicle (general) with explicit inventoryId from JS
local function computerButtonCallback(buttonId, inventoryId)
  print("[computer.lua] computerButtonCallback() called - buttonId: " .. tostring(buttonId) .. ", inventoryId: " .. tostring(inventoryId))
  local functionData = nil
  if inventoryId and computerFunctions.vehicleSpecific[inventoryId] and computerFunctions.vehicleSpecific[inventoryId][buttonId] then
    functionData = computerFunctions.vehicleSpecific[inventoryId][buttonId]
  else
    functionData = computerFunctions.general[buttonId]
    if buttonId == "diagnosticsActiveVehicle" then
      M._pendingDiagnosticsInventoryId = inventoryId
    end
  end
  if functionData and functionData.callback then
    functionData.callback(computerId)
  end
end

local function getComputerUIData()
  print("[computer.lua] getComputerUIData() called")
  local data = {}
  local invVehicles = career_modules_inventory.getVehicles()
  local computerFunctionsForUI = deepcopy(computerFunctions)
  computerFunctionsForUI.vehicleSpecific = {}
  for inventoryId, computerFunction in pairs(computerFunctions.vehicleSpecific) do
    if invVehicles and invVehicles[inventoryId] then
      computerFunctionsForUI.vehicleSpecific[tostring(inventoryId)] = computerFunction
    end
  end
  local vehiclesForUI = {}
  for _, vehicleData in ipairs(menuData.vehiclesInGarage) do
    local invId = vehicleData.inventoryId
    if invVehicles and invVehicles[invId] then
      local vd = deepcopy(vehicleData)
      local thumb = career_modules_inventory.getVehicleThumbnail(invId)
      if thumb then
        vd.thumbnail = thumb .. "?" .. (vd.dirtyDate or "")
      end
      vd.inventoryId = tostring(invId)
      table.insert(vehiclesForUI, vd)
    end
  end
  data.computerFunctions = computerFunctionsForUI
  data.vehicles = vehiclesForUI
  data.facilityName = computerFacilityName
  data.resetActiveVehicleIndex = menuData.resetActiveVehicleIndex
  data.computerId = computerId
  return data
end

local function onMenuClosed()
  print("[computer.lua] onMenuClosed() called")
  if tether then tether.remove = true tether = nil end
end

local function closeMenu()
  print("[computer.lua] closeMenu() called")
  career_career.closeAllMenus()
end

local function openComputerMenuById(id)
  print("[computer.lua] openComputerMenuById() called with id: " .. tostring(id))
  local computer = freeroam_facilities.getFacility("computer", id)
  M.openMenu(computer)
end

M.reasons = {
  tutorialActive = { type = "text", label = "Disabled during tutorial." },
  needsRepair    = { type = "needsRepair", label = "The vehicle needs to be repaired first." }
}

local function getComputerId() return computerId end

M.openMenu = openMenu
M.openComputerMenuById = openComputerMenuById
M.onMenuClosed = onMenuClosed
M.closeMenu = closeMenu
M.getComputerUIData = getComputerUIData
M.computerButtonCallback = computerButtonCallback
M.getComputerId = getComputerId

return M
