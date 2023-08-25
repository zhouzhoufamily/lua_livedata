local DataFactory = require("core.DataFactory")

local function getTime()
    -- return os.time()
    return os.clock()
end

local function test_livedata()
    -- local N = 100 * 10000 -- 差不多上限了 0.22s左右
    local N = 10000 -- 带print差不多上限了 0.125s左右
    local dList = {}
    local obList = {}

    local t = getTime()

    for i = 1, N do
        local d = DataFactory:newLiveData({ value = i }, i)
        dList[#dList + 1] = d

        local ob = {
            ---@param data LiveData
            onLiveUpdate = function(sender, data)
                print(data._ldname, data.value)
            end
        }
        obList[#obList + 1] = ob

        DataFactory:bindObserver(ob, d)
        -- print(i)
    end

    local t1 = getTime()
    print("---dt1", t1 - t)

    for i, v in ipairs(dList) do
        if i % 2 == 0 then
            v.value = i / 2
        end
    end

    local t2 = getTime()
    print("---dt2", t2 - t1)

    DataFactory:doCheckNotifyList()

    local t3 = getTime()
    print("---dt3", t3 - t2)

    DataFactory:doCheckNotifyList()
    local t4 = getTime()
    print("---dt4", t4 - t3)
end

local function test_livedata_supper()
    local N = 10 * 10000 -- 差不多上限了 0.22s左右
    -- local N = 1000 -- 带print差不多上限了 0.15s左右
    local dsList = {}
    local dList = {}
    local obsList = {}
    local obList = {}

    for i = 1, N / 10 do
        local d = DataFactory:newLiveData({ value = i }, i)
        dsList[#dsList + 1] = d
        dList[#dList + 1] = d

        local ob = {
            ---@param data LiveData
            onLiveUpdate = function(sender, data)
                -- print(data._ldname .. "sss", data.value)
            end
        }
        obsList[#obsList + 1] = ob

        DataFactory:bindObserver(ob, d)
    end

    local t = getTime()

    local floor = math.floor
    local ceil = math.ceil
    for i = 1, N do
        local is = ceil(i / 10)
        local d = DataFactory:newLiveData({ value = i }, i)
        dList[is].vd = d
        dList[#dList + 1] = d

        local ob = {
            ---@param data LiveData
            onLiveUpdate = function(sender, data)
                -- print(data._ldname, data.value)
            end
        }
        obList[#obList + 1] = ob

        DataFactory:bindObserver(ob, d)
        -- print(i)
    end

    local t1 = getTime()
    print("---dt1", t1 - t)

    for i, v in ipairs(dList) do
        if i % 2 == 0 then
            v.value = i / 2
        end
    end

    local t2 = getTime()
    print("---dt2", t2 - t1)

    DataFactory:doCheckNotifyList()

    local t3 = getTime()
    print("---dt3", t3 - t2)

    DataFactory:doCheckNotifyList()
    local t4 = getTime()
    print("---dt4", t4 - t3)
end

---测试多重父类关联
local function test_livedata_multi_supper()
    local da = DataFactory:newLiveData({}, "a")
    local oba = {
        ---@param data LiveData
        onLiveUpdate = function(sender, data)
            print(data._ldname)
        end
    }
    DataFactory:bindObserver(oba, da)

    local db = DataFactory:newLiveData({}, "b")
    local obb = {
        ---@param data LiveData
        onLiveUpdate = function(sender, data)
            print(data._ldname)
        end
    }
    DataFactory:bindObserver(obb, db)

    local dc = DataFactory:newLiveData({}, "c")
    local obc = {
        ---@param data LiveData
        onLiveUpdate = function(sender, data)
            print(data._ldname)
        end
    }
    DataFactory:bindObserver(obc, dc)

    da.child = db

    db.child = dc

    print("=====check 1")
    DataFactory:doCheckNotifyList()

    dc.value = 1
    print("=====check 2")
    DataFactory:doCheckNotifyList()

    -- dc.child = da -- assert LiveData has loop refrence
end

---测试print输出耗时
local function test_print()
    local t = getTime()
    print("----")
    print("dt", getTime() - t)
    -- body
end

local function main()
    -- test_print()
    test_livedata()
    -- test_livedata_supper()
    -- test_livedata_multi_supper()
end

main()
