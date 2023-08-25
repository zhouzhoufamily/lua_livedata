---Name 数据工厂
---Date 2023-08-25

local rawget = rawget
local rawset = rawset
local ipairs = ipairs
local type = type

-- local __sig_mt__ = {} -- 使用表做键的话, clone深拷贝后的__sig_mt__会指向新表的地址, 这个唯一键就失效了
local __sig_mt__ = "__sig_mt__" -- 还是指定特殊字符串做键

---实时数据唯一id
local s_auto_ldid = 0

---@class LiveData @实时数据类(为了避免多个LiveData循环引用, 限定 父级数据.__ldid < 子级数据.__ldid)
---@field _ldid number @数据id
---@field _ldname string @类名
---@field _ldsuper LiveData @关联的父数据
---@field _dirtyFlag boolean @脏数据标记
---@field _obList any[] @观察者列表(弱值表)
local LiveData = {
    ---get
    ---@param t LiveData
    ---@param k string
    __index = function(t, k)
        return t[__sig_mt__][k]
    end,
    ---set
    ---@param t LiveData
    ---@param k string
    ---@param v any
    __newindex = function(t, k, v)
        if t[__sig_mt__][k] ~= v then
            t[__sig_mt__]._dirtyFlag = true
            if t._ldsuper then
                t._ldsuper._dirtyFlag = 1
            end
        end
        t[__sig_mt__][k] = v
        if type(v) == "table" and v._ldid then
            assert(t._ldid < v._ldid, "LiveData has loop refrence")
            rawset(v, "_ldsuper", t)
        end
    end
}

---@class DataFactory @数据工厂
---@field _dataList LiveData[] @数据列表(弱值表)
---@field _notifyList LiveData[] @通知列表
local DataFactory = {
    _dataList = {}
}
setmetatable(DataFactory._dataList, { __modde = "v" })

---新建数据
---@param t table @原始数据
---@param name string @数据名
---@return LiveData
function DataFactory:newLiveData(t, name)
    s_auto_ldid = s_auto_ldid + 1
    
    ---@type LiveData
    local data = {}
    data._ldid = s_auto_ldid
    data._ldname = name or "LiveData"
    -- data._dirtyFlag = false
    data._obList = {} -- 观察对象列表
    setmetatable(data._obList, { __mode = "v" })
    data[__sig_mt__] = t
    setmetatable(data, LiveData)

    self._dataList[#self._dataList + 1] = data

    return data
end

---绑定观察者
---@param ob any @观察者
---@param data LiveData @数据
function DataFactory:bindObserver(ob, data)
    if ob.onLiveUpdate == nil or type(ob.onLiveUpdate) ~= "function" then
        print("##DataFactory:bindObserver() ob.onLiveUpdate is nil")
        return
    end

    data._obList[#data._obList + 1] = ob
end

---检查通知列表(通知顺序 子级数据 先于 父级数据)
function DataFactory:doCheckNotifyList()
    local pcall = pcall
    if CC then -- cocos2dx的节点需要检测c++内存中的指针非空
        local isnull = tolua.isnull
        local dList = self._dataList
        local v
        for i = #dList, 1, -1 do
            v = dList[i]
            if v and v[__sig_mt__]._dirtyFlag then -- 避免_dataList被意外插值或删除值, 先判断v非空
                for _, ob in ipairs(v._obList) do
                    if ob and isnull(ob) then
                        pcall(ob.onLiveUpdate, ob, v)
                    end
                end
                v[__sig_mt__]._dirtyFlag = nil
            end
        end
    else
        local dList = self._dataList
        local v
        for i = #dList, 1, -1 do
            v = dList[i]
            if v and v[__sig_mt__]._dirtyFlag then -- 避免_dataList被意外插值或删除值, 先判断v非空
                for _, ob in ipairs(v._obList) do
                    if ob then
                        pcall(ob.onLiveUpdate, ob, v)
                    end
                end
                v[__sig_mt__]._dirtyFlag = nil
            end
        end
    end
end

return DataFactory
