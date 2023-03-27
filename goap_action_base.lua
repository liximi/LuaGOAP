---@class GoapActionBase
---@field name string   #行为名(不可重复)
---@field preconditions table<string, boolean>  #key为状态名称，value为状态值
---@field effects table<string, boolean>        #key为状态名称，value为状态值
---@field cost number   #行为花费,花费越低越容易被执行

local GoapActionBase = Class(function (self, name, preconditions, effects, cost)
    self.name = name
    self.preconditions = preconditions or {}
    self.effects = effects or {}
    self.cost = cost or 1
end)


return GoapActionBase