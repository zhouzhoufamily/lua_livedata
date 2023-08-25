## 一个简单的实时数据监听通知实现
```lua
-- 原始数据表
local originData = {
    id = 1,
    name = "data"
}

-- 创建实时数据
local da = DataFactory:new(originData, "data_name")

-- 任意一个有生命周期的对象, 必须携带onLiveUpdate方法, 实时数据变更时会调用并传入变更的实时数据
local node = cc.Node:create()
node.onLiveUpdate = function(sender, data)
    -- do something
    print(data)
end
...

-- 绑定观察节点
DataFactory:bindObserver(node, da)

-- 实时数据变更, 值相同时不会通知node.onLiveUpdate (特例: 如果实时数据liveData某个值是table A, 那么table A里值的变化不会引起liveData的变化通知)
da.value = 1

...

-- 手动遍历实时数据值变更, 并通知给绑定的观察节点
DataFactory:doCheckNotifyList()

-- next
da.value = 1
DataFactory:doCheckNotifyList() -- 由于da.value值没有变化, 所以不会通知node.onLiveUpdate

-- 实时数据内 赋值 一个实时数据, 方便数据表嵌套监听
-- 子级数据
local db = DataFactory:newLiveData({}, "data_b")
da.child = db -- da.child的值变更了, 所以只要调用DataFactory:doCheckNotifyList()也是会通知给node.onLiveUpdate的

-- 绑定观察节点
DataFactory:bindObserver(node, db)

-- 修改子级数据值
db.value = 1
DataFactory:doCheckNotifyList() -- 父子级数据da和db都绑定了观察者ob, 且子级数据db变更会向父级传递, 所以会通知node.onLiveUpdate两次

-- 不支持循环引用(判定方式为, 通过自增长的实时数据id, 比较创建的先后顺序, 先创建的不允许为后创建的子级)
db.parent = da -- assert: LiveData has loop refrence

```