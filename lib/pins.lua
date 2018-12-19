--- 模块功能：GPIO 功能配置，包括输入输出IO和上升下降沿中断IO
-- @module pins
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2017.09.23 11:34
require"sys"
module(..., package.seeall)
local interruptCallbacks = {}

--- 配置GPIO模式
-- @number pin，GPIO ID
-- GPIO 0到GPIO 31表示为pio.P0_0到pio.P0_31
-- GPIO 32到GPIO XX表示为pio.P1_0到pio.P1_(XX-32)，例如GPIO33 表示为pio.P1_1
-- @param val，number、nil或者function类型
-- 配置为输出模式时，为number类型，表示默认电平，0是低电平，1是高电平
-- 配置为输入模式时，为nil
-- 配置为中断模式时，为function类型，表示中断处理函数
-- @return function
-- 配置为输出模式时，返回的函数，可以设置IO的电平
-- 配置为输入或者中断模式时，返回的函数，可以实时获取IO的电平
-- @usage setOutputFnc = pins.setup(pio.P1_1,0)，配置GPIO 33，输出模式，默认输出低电平；
--执行setOutputFnc(0)可输出低电平，执行setOutputFnc(1)可输出高电平
-- @usage getInputFnc = pins.setup(pio.P1_1,intFnc)，配置GPIO33，中断模式
-- 产生中断时自动调用intFnc(msg)函数：上升沿中断时：msg为cpu.INT_GPIO_POSEDGE；下降沿中断时：msg为cpu.INT_GPIO_NEGEDGE
-- 执行getInputFnc()即可获得当前电平；如果是低电平，getInputFnc()返回0；如果是高电平，getInputFnc()返回1
-- @usage getInputFnc = pins.setup(pio.P1_1),配置GPIO33，输入模式
--执行getInputFnc()即可获得当前电平；如果是低电平，getInputFnc()返回0；如果是高电平，getInputFnc()返回1
function setup(pin, val)
    -- 关闭该IO
    pio.pin.close(pin)
    -- 中断模式配置
    if type(val) == "function" then
        pio.pin.setdir(pio.INT, pin)
        --注册引脚中断的处理函数
        interruptCallbacks[pin] = val
        return function()
            return pio.pin.getval(pin)
        end
    end
    -- 输出模式初始化默认配置
    if val ~= nil then
        pio.pin.setdir(val==1 and pio.OUTPUT1 or pio.OUTPUT, pin)
    -- 输入模式初始化默认配置
    else
        pio.pin.setdir(pio.INPUT, pin)
    end
    -- 返回一个自动切换输入输出模式的函数
    return function(val,changeDir)
        if changeDir then pio.pin.close(pin) end
        if val ~= nil then
            if changeDir then pio.pin.setdir(pio.OUTPUT, pin) end
            pio.pin.setval(val, pin)
        else
            if changeDir then pio.pin.setdir(pio.INPUT, pin) end
            return pio.pin.getval(pin)
        end
    end
end

--- 关闭GPIO模式
-- @number pin，GPIO ID
--
-- GPIO 0到GPIO 31表示为pio.P0_0到pio.P0_31
--
-- GPIO 32到GPIO XX表示为pio.P1_0到pio.P1_(XX-32)，例如GPIO33 表示为pio.P1_1
-- @usage pins.close(pio.P1_1)，关闭GPIO33
function close(pin)
    pio.pin.close(pin)
end

rtos.on(rtos.MSG_INT, function(msg)
    if interruptCallbacks[msg.int_resnum] == nil then
        log.warn('pins.rtos.on', 'warning:rtos.MSG_INT callback nil', msg.int_resnum)
    end
    interruptCallbacks[msg.int_resnum](msg.int_id)
end)
