---@class GoapActionBase
---@field name string   #行为名(不可重复)
---@field preconditions table<string, fun(current_val:any):boolean, number> #key为状态名称，value为条件函数,第二个返回值代表当前状态与期望状态的差异,值越小表示越接近期望状态(建议最小为0),该返回值会在ActionNode:IsSame中用到
---@field effects table<string, fun(current_val:any):any>   #key为状态名称，value为影响函数
---@field cost number   #行为花费,花费越低越容易被执行

local GoapActionBase = Class(function (self, name, preconditions, effects, cost)
    self.name = name
    self.preconditions = preconditions or {}
    self.effects = effects or {}
    self.cost = cost or 1
end)


return GoapActionBase