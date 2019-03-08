local makeCallback = require('make-callback')

return function (stream)
  return function (value)
    stream:write(value, makeCallback())
    coroutine.yield()
  end
end