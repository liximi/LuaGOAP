---@class GoapGoal
---@field name string   #目标名称(不可重复)
---@field preconditions table<string, function> #key为状态名称，value为条件函数，(current_val:any)=>boolean
local GoapGoal = Class(function (self, name, preconditions)
    self.name = name
    self.preconditions = preconditions or {}
end)

return GoapGoal