--- 模块功能：电话簿管理
-- @module pb
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.10

module(..., package.seeall)

require"ril"

local req = ril.request

local storagecb,readcb,writecb,deletecb

--- 设置电话本存储区域
-- @string storage, 存储区域字符串，仅支持"ME"和"SM"
-- @param cb, 设置后的回调函数
--
-- 回调方式为cb(result)，result为true表示成功，false或者nil表示失败
-- @return 无
-- @usage pb.setStorage(storage,cb)
function setStorage(storage,cb)
	if storage=="SM" or storage=="ME" then
		storagecb = cb
		req("AT+CPBS=\"" .. storage .. "\"" )
	end
end
-- 查找用户名是否存在
-- @string name，姓名
-- @return boole，true存在，false不存在
-- @usage pb.find(name)
function find(name)
	if name == "" or name == nil then
		return	false
	end
	req("AT+CPBF=\"" .. name .. "\"" )
	return true
end

--- 读取一条电话本记录
-- @number index，电话本在存储区的位置
-- @function cb，function类型，读取后的回调函数
--
-- 回调方式为cb(result,name,number)：result为true表示成功，false或者nil表示失败；name为姓名；number为号码
-- @usage pb.read(1,cb)
function read(index,cb)
	if index == "" or index == nil then
		return false
	end
	readcb = cb
	req("AT+CPBR=" .. index)
end

--- 写入一条电话本记录
-- @number index，电话本在存储区的位置
-- @string name，姓名
-- @string num，号码
-- @function cb, functionl类型，写入后的回调函数
--
-- 回调方式为cb(result)：result为true表示成功，false或者nil表示失败
-- @return 无
-- @usage pb.write(1,"zhangsan","13233334444",cb)
function write(index,name,num,cb)
	if num == nil or name == nil or index == nil then
		return false
	end
	writecb = cb
	req("AT+CPBW=" .. index .. ",\"" .. num .. "\"," .. "129" .. ",\"" .. name .. "\"" )
	return true
end


--- 删除一条电话本记录
-- @number index, 电话本在存储区的位置
-- @function cb, function类型，删除后的回调函数
--
-- 回调方式为cb(result)：result为true表示成功，false或者nil表示失败
-- @return 无
-- @usage pb.delete(1,cb)
function delete(index,cb)
	if index == "" or index == nil then
		return false
	end
	deletecb = cb
	req("AT+CPBW=" .. index)
	return true
end

local function pbrsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+%u+%?*)")
	intermediate = intermediate or ""

	if prefix == "+CPBF"  then
		local name = string.match(cmd,"AT%+CPBF%s*=%s*\"(%w*)\"")
		if intermediate == "" then
			sys.subscribe("PB_FIND_CNF",success,"","",name)
		else
			for w in string.gmatch(intermediate, "(.-)\r\n") do
				local index,n = string.match(w,"+CPBF:%s*(%d+),\"([#%*%+%d]*)\",%d+,")
				index = index or ""
				n = n or ""
				sys.subscribe("PB_FIND_CNF",success,index,n,name)
			end
		end
	elseif prefix == "+CPBR" then
		local index = string.match(cmd,"AT%+CPBR%s*=%s*(%d+)")
		local num,name = string.match(intermediate,"+CPBR:%s*%d+,\"([#%*%+%d]*)\",%d+,\"(%w*)\"")
		num,name = num or "",name or ""
		sys.subscribe("PB_READ_CNF",success,index,num,name)
		local cb = readcb
		readcb = nil
		if cb then cb(success,name,num) return end
	elseif prefix == "+CPBW" then
		sys.subscribe("PB_WRITE_CNF",success)
		local cb = writecb
		writecb = nil
		if cb then cb(success) return end
		cb = deletecb
		deletecb = nil
		if cb then cb(success) return end
	elseif prefix == "+CPBS?" then
		local storage,used,total = string.match(intermediate,"+CPBS:%s*\"(%u+)\",(%d+),(%d+)")
		used,total = tonumber(used),tonumber(total)
		sys.subscribe("CPBS_READ_CNF",success,storage,used,total)
	elseif prefix == "+CPBS" then
		local cb = storagecb
		storagecb = nil
		if cb then cb(success) return end
    end
end

ril.regRsp("+CPBF",pbrsp)
ril.regRsp("+CPBR",pbrsp)
ril.regRsp("+CPBW",pbrsp)
ril.regRsp("+CPBS",pbrsp)
ril.regRsp("+CPBS?",pbrsp)
