---@class GoapGoal
---@field name string   #目标名称(不可重复)
---@field preconditions table<string, fun(current_val:any):boolean, number> #key为状态名称，value为条件函数,第二个返回值代表当前状态与期望状态的差异,值越小表示越接近期望状态(建议最小为0),该返回值会在ActionNode:IsSame中用到
local GoapGoal = Class(function (self, name, preconditions)
    self.name = name
    self.preconditions = preconditions or {}
end)

return GoapGoal