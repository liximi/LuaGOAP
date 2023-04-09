---@class GoapActionBase
---@field name string   #行为名(不可重复)
---@field preconditions table<string, fun(current_val:any):boolean, number|boolean|string|nil> #key为状态名称，value为条件函数,第二个返回值代表当前状态与期望状态的差异,必须是可以直接使用等于符号进行判断的数据类型(非引用类型),该返回值会在ActionNode:IsSame中用到
---@field effects table<string, fun(current_val:any):any>   #key为状态名称，value为影响函数
---@field cost number   #行为花费,花费越低越容易被执行

local GoapActionBase = Class(function (self, name, preconditions, effects, cost)
    self.name = name
    self.preconditions = preconditions or {}
    self.effects = effects or {}
    self.cost = cost or 1
end)


return GoapActionBase