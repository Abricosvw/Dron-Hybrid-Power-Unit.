-- Lua script for CAN communication with VESC

-- Установка CAN ID для общения с VESC
local VESC_CAN_ID_RPM = 0x200 -- CAN ID для сообщений о RPM
local VESC_CAN_ID_TEMP = 0x201 -- CAN ID для сообщений о температуре

-- Функция для отправки CAN сообщения на VESC
function sendCanMessage(data, can_id)
    local message = {
        id = can_id,
        data = data,
        extended = false
    }
    canSend(message)
end

-- Функция для обработки входящих CAN сообщений от VESC
function processCanMessage(message)
    if message.id == VESC_CAN_ID_RPM then
        -- Обработка сообщения о RPM
        local data = message.data
        local rpm = data[1] * 256 + data[2] -- Предполагается, что RPM передается в первых двух байтах
        print("Получен RPM от VESC: " .. rpm)
        
        -- Добавьте вашу логику обработки RPM здесь
        
    elseif message.id == VESC_CAN_ID_TEMP then
        -- Обработка сообщения о температуре
        local data = message.data
        local temp = data[1] -- Предполагается, что температура передается в первом байте
        print("Получена температура от VESC: " .. temp)
        
        -- Добавьте вашу логику обработки температуры здесь
    end
end

-- Фиктивная функция для симуляции определения функции canReceiveCallback
function canReceiveCallback(callback)
    print("Функция canReceiveCallback определена")
    -- Здесь вы зарегистрируете callback с системой CAN
end

-- Регистрация обратного вызова CAN
canReceiveCallback(processCanMessage)

-- Пример использования: отправка CAN сообщения на VESC
local exampleDataRPM = {0x01, 0x02} -- Пример данных RPM
sendCanMessage(exampleDataRPM, VESC_CAN_ID_RPM)

local exampleDataTemp = {0x03} -- Пример данных температуры
sendCanMessage(exampleDataTemp, VESC_CAN_ID_TEMP)