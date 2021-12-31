local Formatters=require 'formatters'
local Monosaw={}

function Monosaw:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  return o
end

function Monosaw:init()
  params:add_group("MONOSAW",4)
  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  params:add{type="control",id="lpfmin",name="min lpf",
    controlspec=filter_freq,formatter=Formatters.format_freq,action=function(x)
    end
  }
  osc.event=function(path,args,from)
    if path=="lpffreq" then
      print(args[1])
    end
  end
end

function Monosaw:key(k,z)
  if global_shift then
    if k==1 then
    elseif k==2 then
    elseif k==3 then
    end
    do return end
  end
  if k==1 then
  elseif k==2 then
  elseif k==3 then
  end
end

function Monosaw:enc(k,d)
  if global_shift then
    if k==1 then
    elseif k==2 then
    elseif k==3 then
    end
    do return end
  end
  if k==1 then
  elseif k==2 then
  elseif k==3 then
  end
end

function Monosaw:draw()
end

return Monosaw
