local Utils = {}

-- Convert a list into an interator
function Utils.listIter(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

-- Convert an iterator into a list
function Utils.iterList(it)
  local results = {}
  local i = 1
  for value in it do
    results[i] = value
    i = i + 1
  end
  return results
end

-- Return true if two lists are identical, false if not.
function Utils.listEqual(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

return Utils
