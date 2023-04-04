---@alias GoapPlan string[] #each item: action_name(string)

---@class GoapAgent
---@field inst table                            #该代理挂载的对象
---@field state_list table<string, function>    #key为状态名称,value为查询状态值的函数,接受agent.inst作为参数
---@field action_list GoapActionBase[]          #所有可用行为
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
---@return table<string, boolean>
function GoapAgent:GetCurrentStates()
    local res = {}
    for state_name, checker in pairs(self.state_list) do
        res[state_name] = checker(self.inst) or false
    end
    return res
end

--- 检查状态是否符合期望
---@param state_name string
---@param expect_val boolean
---@return boolean
function GoapAgent:CheckState(state_name, expect_val)
    assert(self.state_list[state_name])
    return self.state_list[state_name](self.inst) == expect_val
end

--- 设置所有可用状态
---@param states table<string, function>
function GoapAgent:SetStates(states)
    self.state_list = states
end

--- 设置所有可选行为
---@param actions table<string, GoapActionBase>
function GoapAgent:SetActions(actions)
    self.action_list = actions
end


--- 检查base_states是否满足target_states的要求,即base_states的状态完全覆盖target_states的状态
---@param base_state table<string, boolean>
---@param target_state table<string, boolean>
---@return boolean
local function StatesEqual(base_state, target_state)
    for state_name, val in pairs(target_state) do
        if base_state[state_name] ~= val then
            return false
        end
    end
    return true
end

--- 计算target_state与base_state之间有多少个状态未满足
---@param base_state table<string, boolean>
---@param target_state table<string, boolean>
---@return integer
local function GetDiffNum(base_state, target_state)
    local num = 0
    for state_name, val in pairs(target_state) do
        if base_state[state_name] ~= val then
            num = num + 1
        end
    end
    return num
end

--- 检查current_state是否满足action的precondition
---@param action GoapActionBase
---@param current_state table<string, boolean>
---@return boolean
local function CanPerform(action, current_state)
    for state_name, expect_val in pairs(action.preconditions) do
        if current_state[state_name] ~= expect_val then
            return false
        end
    end
    return true
end

--- 将action的effects应用到base_state上
---@param action GoapActionBase
---@param base_state table<string, boolean>
---@return table<string, boolean>
local function ApplyEffects(action, base_state)
    for state_name, val in pairs(action.effects) do
        base_state[state_name] = val
    end
    return base_state
end

--- 为具体的目标计算行为计划, 如果无法计算出计划将返回nil(该函数在ChatGPT生成的基础上修改)
---@param goal GoapGoal     #目标
---@param debug_print boolean|nil   #如果为true,将输出计划信息
---@return GoapPlan|nil
function GoapAgent:PlanForGoal(goal, debug_print)
    -- 获取起始状态和目标状态
    local start_state = self:GetCurrentStates()
    local goal_state = goal.states
    if debug_print then
        print("- Current State:")
        for state_name, val in pairs(start_state) do
            print("--- "..state_name..": "..tostring(val))
        end
        print("- Goal State:")
        for state_name, val in pairs(goal_state) do
            print("--- "..state_name..": "..tostring(val))
        end
    end

    -- 初始化open集合和closed集合
    local open_list = { { state = start_state, cost = {f = 0, g = 0, h = 0}, actions = {} } }
    local closed_list = {}

    -- 循环搜索
    while #open_list > 0 do
        -- 选择open集合中代价最小的状态
        table.sort(open_list, function(a, b)
            if a.cost.f < b.cost.f then
                return true
            elseif a.cost.f == b.cost.f and a.cost.h < b.cost.h then
                return true
            end
            return false
        end)
        local current_node = table.remove(open_list, 1)
        -- 如果当前状态已经在closed集合中，跳过
        local is_in_closed_list = false
        for i, node in ipairs(closed_list) do
            if StatesEqual(node.state, current_node.state) then
                is_in_closed_list = true
                break
            end
        end
        if not is_in_closed_list then
            -- 如果当前状态和目标状态相等，返回计划
            if StatesEqual(current_node.state, goal_state) then
                if debug_print then
                    print("- Get Plan!")
                    for i, action in ipairs(current_node.actions) do
                        print("--- "..i.."  "..action)
                    end
                end
                return current_node.actions
            end
            -- 将当前状态加入closed集合
            table.insert(closed_list, current_node)
            -- 拓展所有可行的行动
            for i, action in ipairs(self.action_list) do
                if CanPerform(action, current_node.state) then
                    -- 创建新状态
                    local new_state = ApplyEffects(action, deepcopy(current_node.state))

                    -- 将新状态加入open集合
                    local new_cost = {g = current_node.cost.g + action.cost}
                    new_cost.h = GetDiffNum(new_state, goal_state)
                    new_cost.f = new_cost.g + new_cost.h
                    local new_actions = deepcopy(current_node.actions)
                    table.insert(new_actions, action.name)
                    table.insert(open_list, { state = new_state, cost = new_cost, actions = new_actions })
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
        for state_name, expect_val in pairs(goal.states) do
            if not self:CheckState(state_name, expect_val) then
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