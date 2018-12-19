--- 模块功能：MQTT客户端数据发送处理
-- @author openLuat
-- @module mqtt.mqttOutMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28


module(...,package.seeall)
--串口模块
require "testUart"
local function print(...)
	_G.print("test",...)
end
--- MQTT客户端是否有数据等待发送
-- @return 有数据等待发送返回true，否则返回false
-- @usage mqttOutMsg.waitForSend()
function waitForSend()
   if testUart.rdbuf~="" then
     return true
   else return false
    end

end

--- MQTT客户端数据发送处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttOutMsg.proc(mqttClient)
function proc(mqttClient)
   -- print("testUart.rdbuf",testUart.rdbuf)
    if testUart.rdbuf ~="" then
       if not mqttClient:publish("/gotopic",testUart.rdbuf,0) then
        log.error("mqttTask.mqttOutMsg proc error")
        return false
       end
    end
   testUart.rdbuf =""
    return true
end
