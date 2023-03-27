require "class"
require "utils"
local GOAP = require "goap"

--[[测试用例说明:
    Goal:取火、进食
    Actions:拾取木材、购买木材、添加燃料、制作篝火、采集浆果、购买浆果、吃浆果
    States:体温、是否在黑暗中、是否有足够的钱、是否有木材可以拾取、是否拥有木材、是否拥有浆果、是否有浆果可以采集、饥饿值
]]


local items = {
    log = {pickup = true, buy = true, gather = false},
    berry = {pickup = true, buy = true, gather = true, eat = true},
    campfire = {pickup = false, buy = true, gather = false, make = true},
}


--准备可用状态 state_name = state_collector
local states = {
    --temperature
    suitable_temperature = function(inst)
        return inst.temperature <= 30 and inst.temperature >= 14
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
        return inst.items[item] and inst.items[item] > 0 or false
    end
    if data.pickup then
        states["can_pickup_"..item] = function(inst)
            return false
        end
    end
    if data.buy then
        states["has_enough_money_for_"..item] = function(inst)
            return inst.money >= 10
        end
    end
    if data.gather then
        states["can_gather_"..item] = function(inst)
            return true
        end
    end
end


--准备可用行为
local GoapAction_PickUp = Class(GOAP.Action, function (self, item, cost)
    local name = "pickup_"..item
    local preconditions = {["can_pickup_"..item] = true}
    local effects = {["has_"..item] = true}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)
local GoapAction_Buy = Class(GOAP.Action, function (self, item, cost)
    local name = "buy_"..item
    local preconditions = {["has_enough_money_for_"..item] = true}
    local effects = {["has_"..item] = true}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)
local GoapAction_Make = Class(GOAP.Action, function (self, item, cost)
    local name = "make_"..item
    local ingredients = {"log"}
    local preconditions = {}
    for _, ingredient in ipairs(ingredients) do
        preconditions["has_"..ingredient] = true
    end
    local effects = {["has_"..item] = true}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)
local GoapAction_Gather = Class(GOAP.Action, function (self, item, cost)
    local name = "gather_"..item
    local preconditions = {["can_gather_"..item] = true}
    local effects = {["has_"..item] = true}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)
local GoapAction_Eat = Class(GOAP.Action, function (self, item, cost)
    local name = "eat_"..item
    local preconditions = {["has_"..item] = true}
    local effects = {is_hunger = false}
    GOAP.Action._ctor(self, name, preconditions, effects, cost)
end)

local actions = {
    GOAP.Action("refuelling", {has_campfire = true, has_log = true}, {suitable_temperature = true, is_in_dark = false}, 1),
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
    GOAP.Goal("MakeAFire", { suitable_temperature = true, is_in_dark = false, }),
    GOAP.Goal("DontStarve", { is_hunger = false }),
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
MyAgent:Plan(true)

print("\ndone")