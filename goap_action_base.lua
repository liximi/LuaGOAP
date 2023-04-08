---@class GoapActionBase
---@field name string   #行为名(不可重复)
---@field preconditions table<string, function> #key为状态名称，value为条件函数，(current_val:any)=>boolean
---@field effects table<string, function>       #key为状态名称，value为影响函数，(current_val:any)=>any
---@field cost number   #行为花费,花费越低越容易被执行

local GoapActionBase = Class(function (self, name, preconditions, effects, cost)
    self.name = name
    self.preconditions = preconditions or {}
    self.effects = effects or {}
    self.cost = cost or 1
end)


return GoapActionBase