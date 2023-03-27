function deepcopy(tab)
    local res = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
            res[k] = deepcopy(v)
        else
            res[k] = v
        end
    end

    return res
end