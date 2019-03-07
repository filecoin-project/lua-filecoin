return function()
    local thread = coroutine.running()
    local done
    return function(err, data)
        if not done then
            done = true
            if err then
                return assert(coroutine.resume(thread, nil, err))
            else
                return assert(coroutine.resume(thread, data or true))
            end
        end
    end
end
