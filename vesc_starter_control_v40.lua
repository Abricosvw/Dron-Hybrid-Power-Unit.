-- Lua rusEFI uaEFI: VESC Starter Control via readPin("PB1") (v40 - Corrected txCan payload variable)

print("--- VESC Starter Control Script v40 Corrected ---")
print("Ensure Pin PB1 INPUT PULL-UP & VESC ID=10 @ CAN Bus #1 @500kbps")

local vesc_id = 10
local button_pin_name = "PB1"
local target_can_bus = 1
local starter_duty_percent = 30.0
local stop_duty_percent = 0.0
local start_duration = 5.0

local is_vesc_sequence_active = false
local previous_button_state = nil
local vesc_start_timer = nil

print("Checking required functions...")
if txCan == nil or readPin == nil or startCrankingEngine == nil or setTickRate == nil or Timer == nil or Timer.new == nil then
    print("!!! Required functions missing! Halting. !!!")
    while true do end
end
print("All required functions available.")

vesc_start_timer = Timer.new()
if vesc_start_timer == nil then 
    print("!!! FATAL ERROR: Timer.new() returned nil! Halting. !!!")
    while true do end 
end
print("Timer object created successfully.")

-- Правильные IEEE754 байты для 30% и 0%
local start_data = {0x00, 0x00, 0x70, 0x35} -- 0.3 (30%) IEEE754 big-endian
local stop_data = {0x00, 0x00, 0x00, 0x00}  -- 0.0 IEEE754

function sendVESCDutyCommand(data_payload, duty_percent)
    local dlc = 4 -- всегда 4 байта данных IEEE754 Float
    print("Sending SET_DUTY=", duty_percent, "% to VESC ID=", vesc_id, "Bus", target_can_bus)
    txCan(target_can_bus, vesc_id, dlc, data_payload)
end

function triggerVESCStarter()
  if not is_vesc_sequence_active then
    print("PB1 PRESSED. Starting VESC sequence.")
    startCrankingEngine()
    vesc_start_timer:reset()
    is_vesc_sequence_active = true
  end
end

function stopVESCStarter(reason)
  if is_vesc_sequence_active then
    print("Stopping VESC. Reason:", reason)
    sendVESCDutyCommand(stop_data, stop_duty_percent)
    is_vesc_sequence_active = false
  end
end

function onTick()
  local current_button_state = readPin(button_pin_name)

  if current_button_state == nil then
    print("Warning: readPin('PB1') returned nil.")
    stopVESCStarter("Nil readPin")
    previous_button_state = nil
    return
  end

  local pressed = 0
  local released = 1

  if previous_button_state == nil then
    previous_button_state = current_button_state
    print("Initialized previous_button_state:", previous_button_state)
    return
  end

  if current_button_state == pressed and previous_button_state == released then
    triggerVESCStarter()
  end

  if current_button_state == released and previous_button_state == pressed then
    stopVESCStarter("Button Released")
  end

  if is_vesc_sequence_active then
    local elapsed = vesc_start_timer:getElapsedSeconds()
    if elapsed < start_duration then
      sendVESCDutyCommand(start_data, starter_duty_percent)
    else
      stopVESCStarter("Timeout")
    end
  end

  previous_button_state = current_button_state
end

setTickRate(20)
print("VESC Starter Control initialized. Waiting for ticks...")
