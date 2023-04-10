---@alias GoapPlan string[] #each item: action_name(string)

---@class GoapAgent
---@field inst table                            #该代理挂载的对象
---@field state_list table<string, fun(inst:table):any>     #key为状态名称,value为查询状态值的函数,接受agent.inst作为参数
---@field action_list table<string, GoapActionBase[]>       #所有可用行为
---@field goal_list GoapGoal[]                  #所有可选择的目标,按照优先级排序,越靠前的越优先考虑
---@field current_goal GoapGoal|nil             #当前设定的目标
---@field current_plan GoapPlan|nil             #当期设定的计划
local GoapAgent = Class(function(self, inst)
    self.inst = inst
    self.state_list = {}
    self.action_list = {}
    self.goal_list = {}
    self.current_goal = nil
    self.current_plan = nil
end)


--- 设置可选目标,会自动重新计算当前目标
---@param goals GoapGoal[]
function GoapAgent:SetGoals(goals)
    self.goal_list = goals
end

--- 添加可选目标,将该目标按照priority插入可选目标列表中
---@param goal GoapGoal
---@param priority integer
function GoapAgent:AddGoal(goal, priority)
    local length = #self.goal_list
    if priority >= length then
        table.insert(self.goal_list, goal)
    else
        table.insert(self.goal_list, priority, goal)
    end
end

--- 获取当前的状态值
---@param state_name string
---@return boolean
function GoapAgent:GetCurrentState(state_name)
    assert(self.state_list[state_name])
    return self.state_list[state_name](self.inst) or false
end

--- 获取当前的所有状态值
---@return table<string, any>
function GoapAgent:GetCurrentStates()
    local res = {}
    for state_name, getter in pairs(self.state_list) do
        res[state_name] = getter(self.inst) or false
    end
    return res
end

--- 检查状态是否符合期望
---@param state_name string
---@param checker function
---@return boolean
function GoapAgent:CheckState(state_name, checker)
    assert(self.state_list[state_name])
    local currnet_val = self.state_list[state_name](self.inst)
    return checker(currnet_val)
end

--- 设置所有可用状态
---@param states table<string, function>
function GoapAgent:SetStates(states)
    self.state_list = states
end

--- 设置所有可选行为，会将行为按照其effects里的state和value进行分类储存
---@param actions GoapActionBase[]
function GoapAgent:SetActions(actions)
    self.action_list = {}
    for _, action in ipairs(actions) do
        for state_name, val in pairs(action.effects) do
            if not self.action_list[state_name] then
                self.action_list[state_name] = {}
            end
            table.insert(self.action_list[state_name], action)
        end
    end
end

----------------------------------------------------------
---@class ActionNode
---@field action GoapActionBase
---@field preconditions table<string, fun(current_val:any):boolean>
---@field parent_node ActionNode
---@field cost_h integer
---@field cost_g integer
---@field cost integer
local ActionNode = Class(function (self, action, preconditions, parent_node, init_state)
    self.action = action
    self.preconditions = preconditions or {}
    self.parent_node = parent_node
    self.cost_h = self:CalcuCostH()
    self.cost_g = self:CalcuCostG(init_state)
    self.cost = self.cost_h + self.cost_g
end)

--- 计算当前Node的CostH,即当前Node到GoalState的距离
---@return integer
function ActionNode:CalcuCostH()
    local parent_h = self.parent_node and self.parent_node.cost_h or 0
    return parent_h + (self.action and self.action.cost or 0)
end

--- 计算当前Node的CostG,即当前Node到InitState的距离
---@return integer
function ActionNode:CalcuCostG(init_state)
    local g = 0
    for state_name, checker in pairs(self.preconditions) do
        if init_state and init_state[state_name] then
            local res, diff = checker(init_state[state_name])
            g = g + diff
        else
            g = g + 1
        end
    end
    return g
end

--- 比较两个ActionNode的未满足条件是否一致
---@param init_state table<string, any>
---@param node ActionNode
---@return boolean
function ActionNode:IsSame(init_state, node)
    local num = 0
    for state_name, checker in pairs(node.preconditions) do
        local current_val = init_state[state_name]
        if not self.preconditions[state_name] then
            return false
        end
        local val_self, diff_self = self.preconditions[state_name](current_val)
        local val_node, diff_node = checker(current_val)
        if val_self ~= val_node or diff_self ~= diff_node then
            return false
        end
        num = num + 1
    end
    for state_name, checker in pairs(self.preconditions) do
        num = num - 1
    end
    return num == 0
end

--- 检查当前Node所有的前提条件是否都满足了
---@param init_state table<string, any>
---@return boolean
function ActionNode:IsSatisfied(init_state)
    for state_name, checker in pairs(self.preconditions) do
        if not checker(init_state[state_name]) then
            return false
        end
    end
    return true
end

--- 获取当前Node需要纳入计划的所有Action(string)
---@param action_list string[]|nil
---@param cost_list integer[]|nil
---@return string[], integer[]
function ActionNode:GetActionList(action_list, cost_list)
    action_list = action_list or {}
    cost_list = cost_list or {}
    if self.action then
        table.insert(action_list, self.action.name)
        table.insert(cost_list, self.action.cost)
    end
    if self.parent_node then
        self.parent_node:GetActionList(action_list, cost_list)
    end
    return action_list, cost_list
end

--- 打印当前Node的信息
function ActionNode:Print()
    local str = {"------ActionNode------", tostring(self)}
    table.insert(str, "action: "..tostring(self.action and self.action.name or nil))
    table.insert(str, "preconditions:")
    for state_name, checker in pairs(self.preconditions) do
        table.insert(str, "-- "..state_name.." "..tostring(checker))
    end
    table.insert(str, "parent_node: "..tostring(self.parent_node).."  "..tostring(self.parent_node and self.parent_node.action and self.parent_node.action.name or nil))
    table.insert(str, "cost: "..tostring(self.cost).." to_init:"..tostring(self.cost_g).." + from_goal:"..tostring(self.cost_h))
    table.insert(str, "----------------------")
    print(table.concat(str, "\n"))
end

----------------------------------------------------------

--- 为具体的目标计算行为计划, 如果无法计算出计划将返回nil
---@param goal GoapGoal     #目标
---@param debug_print boolean|nil   #如果为true,将输出计划信息
---@return GoapPlan|nil
function GoapAgent:PlanForGoal(goal, debug_print)
    -- 获取起始状态和目标状态
    local goal_state = deepcopy(goal.preconditions)
    local init_state = self:GetCurrentStates()
    if debug_print then
        print("- Current State:")
        for state_name, val in pairs(init_state) do
            print("--- "..state_name..": "..tostring(val))
        end
        print("- Goal State:")
        for state_name, val in pairs(goal_state) do
            print("--- "..state_name..": "..tostring(val))
        end
    end

    --初始化当前寻路节点
    local current_node = ActionNode(nil, goal_state, nil, init_state)
    --初始化处理过的和未处理过的ActionNode列表
    local open_list = {current_node}    ---@type ActionNode[]
    local closed_list = {}              ---@type ActionNode[]

    while #open_list > 0 do
        --取出cost最小的未搜索过的Node
        table.sort(open_list, function (a, b)
            if a.cost == b.cost then
                return a.cost_g < b.cost_g
            else
                return a.cost < b.cost
            end
        end)
        current_node = table.remove(open_list, 1)
        --将current_node加入closed_list，表示已经搜索过了
        table.insert(closed_list, current_node)
        -- current_node:Print()
        --如果未满足状态列表为空，则说明完成了计划
        if current_node:IsSatisfied(init_state) then
            local actions, costs = current_node:GetActionList()
            if debug_print then
                print("- <Get Plan>")
                local total_cost = 0
                for i, action in ipairs(actions) do
                    local cost = costs[i]
                    print("--- "..i.."  "..action.." | cost: "..cost)
                    total_cost = total_cost + cost
                end
                print("--- Total cost: "..total_cost)
            end
            return actions
        end

        --遍历当前所有没有满足的条件，在self.action_list中直接查询有没有能满足的action，有就加入open_list
        for state_name, checker in pairs(current_node.preconditions) do
            if not self.action_list[state_name] and not checker(init_state[state_name]) then
                break   --该条件永远不可能被满足
            end
            local current_check_result, current_check_diff = checker(init_state[state_name])
            if not current_check_result then
                for _, action in ipairs(self.action_list[state_name]) do
                    local is_vaild = true
                    local preconditions = deepcopy(current_node.preconditions)
                    for state_name, effector in pairs(action.effects) do
                        local old_checker = preconditions[state_name]
                        if old_checker then
                            local new_checker = function(current_val)
                                current_val = effector(current_val)
                                return old_checker(current_val)
                            end
                            preconditions[state_name] = new_checker
                            local new_check_result, new_check_diff = new_checker(init_state[state_name])
                            --如果新Node会导致与期望状态的差异越来越大或没有变化，就不采用
                            if current_check_result and not new_check_result then
                                is_vaild = false
                            elseif current_check_diff <= new_check_diff then
                                is_vaild = false
                            end
                        end
                    end
                    if is_vaild then
                        for state_name, checker in pairs(action.preconditions) do
                            if not preconditions[state_name] then
                                preconditions[state_name] = checker
                            end
                        end
                        local new_node = ActionNode(action, preconditions, current_node, init_state)
                        -- 如果当前状态已经在closed集合中，就不加入open_list
                        local is_in_closed_list = false
                        for _, node in ipairs(closed_list) do
                            if node:IsSame(init_state, new_node) then
                                is_in_closed_list = true
                                break
                            end
                        end
                        if not is_in_closed_list then
                            table.insert(open_list, new_node)
                        end
                    end
                end
            end
        end
    end

    -- 没有找到合适的计划，返回nil
    if debug_print then print("- Not find vaild plan, return nil") end
    return nil
end

--- 计算当前应该选择的目标及其计划, 总是选出可以达到的目标, 如果没有可以达到的目标, 则不会设置目标和计划
---@param debug_print boolean
---@return nil
function GoapAgent:Plan(debug_print)
    if debug_print then print("[ GOAP GoapAgent:Plan() Debug Info ]") end
    -- 选出所有可用的目标(期望状态未满足的)
    local vaild_goals = {}
    for i, goal in ipairs(self.goal_list) do
        for state_name, checker in pairs(goal.preconditions) do
            if not self:CheckState(state_name, checker) then
                table.insert(vaild_goals, goal)
            end
        end
    end

    for _, goal in ipairs(vaild_goals) do
        if debug_print then print("\n- Trying to find plan for < "..goal.name.." >") end
        local plan = self:PlanForGoal(goal, debug_print)
        if plan then
            self.current_goal = goal
            self.current_plan = plan
            return
        end
    end
    if debug_print then print("- Cant find any plan for all goals!") end
end

return GoapAgent