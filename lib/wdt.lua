--- 模块功能：外部硬件看门狗
-- @module wdt
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.23 11:34

module(..., package.seeall)

require "pins"

--[[模块和看门狗互喂任务
-- @return 无
-- @usage local RST_SCMWD_PIN,RST_SCMWD_PIN
-- @usage taskWdt()
--]]
local function taskWdt(rst, wd)
    -- 初始化喂狗引脚电平(初始高电平，喂狗拉低2秒)
    rst(1)
    wd(1)
    -- 模块<--->看门狗  相互循环喂脉冲
    while true do
        -- 模块 ---> 看门狗 喂脉冲
        wd(0)
        log.info("wdt.taskWdt", "AirM2M --> WATCHDOG : OK")
        sys.wait(2000)
        -- 看门狗 ---> 模块 喂脉冲
        wd(nil,true)
        for i = 1, 30 do
            if 0 ~= wd() then
                sys.wait(100)
            else
                log.info("wdt.taskWdt", "AirM2M <-- WatchDog : OK")
                break
            end
            -- 狗死了
            if 30 == i then
                -- 复位狗
                rst(0)
                log.error("wdt.taskWdt", "WatchDog <--> AirM2M didn't respond : wdt reset 153b")
                sys.wait(100)
                rst(1)
            end
        end
        -- 2分钟后再喂
        sys.wait(120000)
        wd(0,true)
    end
end

--- 配置模块与看门狗通讯IO并启动任务
-- @param rst -- 模块复位单片机引脚(pio.P0_31)
-- @param wd  -- 模块和单片机相互喂狗引脚(pio.P0_29)
-- @return 无
-- @usage setup(pio.P0_31,pio.P0_29)
function setup(rst, wd)
    sys.taskInit(taskWdt, pins.setup(rst, 0), pins.setup(wd, 0))
end
