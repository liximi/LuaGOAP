---@class GoapGoal
---@field name string   #目标名称(不可重复)
---@field states table<string, boolean> #key为状态名称，value为期望状态值
local GoapGoal = Class(function (self, name, states)
    self.name = name
    self.states = states
end)

return GoapGoal