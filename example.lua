require "class"
require "utils"
local GOAP = require "goap"

--[[测试用例说明:
    Goal:取火、进食
    Actions:拾取木材、购买木材、添加燃料、制作篝火、采集浆果、购买浆果、吃浆果
    States:体温、是否在黑暗中、是否有足够的钱、是否有木材可以拾取、是否拥有木材、是否拥有浆果、是否有浆果可以采集、饥饿值
]]


local items = {
    log = {pickup = true, buy = true},
    berry = {buy = true, gather = true, eat = true},
    campfire = {buy = true, make = true},
}


--准备可用状态 state_name = state_collector
local states = {
    --temperature
    temperature = function(inst)
        return inst.temperature
    end,

    --light
    is_in_dark = function(inst)
        return inst.is_in_dark == true
    end,

    --hunger
    is_hunger = function (inst)
        return inst.hunger <= 50
    end,
}
for item, data in pairs(items) do
    states["has_"..item] = function(inst)
        return inst.items[item] or 0
    end
    if data.pickup then
        states["can_pickup_"..item] = function(inst)
            return false
        end
    end
    if data.buy then
        states["money"] = function(inst)
            return inst.money or 0
        end
    end
    if data.gather then
        states["can_gather_"..item] = function(inst)
            return true
        end
    end
end


--准备可用行为
local can_pickup_checker = function (current_val)
    return current_val == true
end
local pickup_effector = function (current_val)
    return current_val + 1
end
local GoapAction_PickUp = Class(GOAP.Action, function (self, item, cost)
    local name = "pickup_"..item
    local preconditions = {["can_pickup_"..item] = can_pickup_checker}
    local effects = {["has_"..item] = pickup_effector}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local has_enough_money_checker = function (current_val)
    return current_val >= 2, 2 - current_val
end
local buy_effector = function (current_val)
    return current_val + 1
end
local GoapAction_Buy = Class(GOAP.Action, function (self, item, cost)
    local name = "buy_"..item
    local preconditions = {["money"] = has_enough_money_checker}
    local effects = {["has_"..item] = buy_effector, money = function (current_val)
        return current_val - 2
    end}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local make_checker = function (current_val)
    return current_val > 0, 1 - current_val
end
local make_effector = function (current_val)
    return current_val + 1
end
local GoapAction_Make = Class(GOAP.Action, function (self, item, cost)
    local name = "make_"..item
    local ingredients = {"log"}
    local preconditions = {}
    for _, ingredient in ipairs(ingredients) do
        preconditions["has_"..ingredient] = make_checker
    end
    local effects = {["has_"..item] = make_effector}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local can_gather_checker = function (current_val)
    return current_val == true
end
local gather_effector = function (current_val)
    return current_val + 1
end
local GoapAction_Gather = Class(GOAP.Action, function (self, item, cost)
    local name = "gather_"..item
    local preconditions = {["can_gather_"..item] = can_gather_checker}
    local effects = {["has_"..item] = gather_effector}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local eat_checker = function (current_val)
    return current_val > 2, 3 - current_val
end
local eat_effector = function (current_val)
    return false
end
local GoapAction_Eat = Class(GOAP.Action, function (self, item, cost)
    local name = "eat_"..item
    local preconditions = {["has_"..item] = eat_checker}
    local effects = {is_hunger = eat_effector}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local actions = {
    GOAP.Action("refuelling",
    {has_campfire = function(current_val)
        return current_val > 0, 1 - current_val
    end, has_log = function(current_val)
        return current_val > 0, 1 - current_val
    end},
    {temperature = function(current_val)
        return 25
    end, is_in_dark = function(current_val)
        return false
    end}, 1),
}
for item, data in pairs(items) do
    if data.pickup then
        table.insert(actions, GoapAction_PickUp(item, 2))
    end
    if data.buy then
        table.insert(actions, GoapAction_Buy(item, 2))
    end
    if data.gather then
        table.insert(actions, GoapAction_Gather(item))
    end
    if data.make then
        table.insert(actions, GoapAction_Make(item))
    end
    if data.eat then
        table.insert(actions, GoapAction_Eat(item))
    end
end


--准备可用目标
--goal_name = GoapGoal
local goals = {
    GOAP.Goal("MakeAFire", { temperature = function (current_val)
        return current_val >= 14 and current_val <= 30
    end, is_in_dark = function (current_val)
        return current_val == false
    end, }),
    GOAP.Goal("DontStarve", { is_hunger = function (current_val)
        return current_val == false
    end }),
}


--创建Agent
local inst = {
    temperature = 37,
    money = 5,
    hunger = 49,
    items = {
        log = 0,
        berry =0,
    },
    is_in_dark = false
}
local MyAgent = GOAP.Agent(inst)    ---@type GoapAgent
MyAgent:SetStates(states)
MyAgent:SetActions(actions)
MyAgent:SetGoals(goals)


--进行计划
local t = os.clock()
for i = 1, 1 do
    MyAgent:Plan(true)
end
print("cost time: "..(os.clock() - t))

print("\ndone")