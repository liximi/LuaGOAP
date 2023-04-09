---@class GoapGoal
---@field name string   #目标名称(不可重复)
---@field preconditions table<string, fun(current_val:any):boolean, number|boolean|string|nil> #key为状态名称，value为条件函数,第二个返回值代表当前状态与期望状态的差异,必须是可以直接使用等于符号进行判断的数据类型(非引用类型),该返回值会在ActionNode:IsSame中用到
local GoapGoal = Class(function (self, name, preconditions)
    self.name = name
    self.preconditions = preconditions or {}
end)

return GoapGoal