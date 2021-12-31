local Formatters=require 'formatters'
local Monosaw={}

function Monosaw:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  return o
end

function Monosaw:init()
  self.lpffreq=20000
  params:add_group("MONOSAW",5)
  local filter_freq=controlspec.new(20,20000,'exp',0,20000,'Hz')
  params:add{type="control",id="monosaw_amp",name="amp",
    controlspec=controlspec.new(0.0,1,'lin',0.1,0.0,"amp",0.1/1),action=function(x)
      engine.amp(x)
    end
  }
  params:add{type="control",id="monosaw_detuning",name="detuning",
    controlspec=controlspec.new(0,100,'lin',0.25,2.5,"%",0.25/100),action=function(x)
      engine.detuning(x/100)
    end
  }
  params:add{type="control",id="monosaw_lpfmin",name="min lpf",
    controlspec=filter_freq,formatter=Formatters.format_freq,action=function(x)
      engine.lpfmin(x)
    end
  }
  params:add{type="control",id="monosaw_lpfadj",name="lpf adj",
    controlspec=filter_freq,formatter=Formatters.format_freq,action=function(x)
      engine.lpfadj(x)
    end
  }
  params:add{type="control",id="monosaw_lpflfo",name="lpf lfo",
    controlspec=controlspec.new(0.025,30,'lin',0.025,0.1,"Hz",0.025/30),action=function(x)
      engine.lpflfo(x)
    end
  }
  params:set("monosaw_detuning",2.4)
  params:set("monosaw_lpfmin",800)
  params:set("monosaw_lpfadj",2000)
  params:set("monosaw_lpflfo",0.2)
  params:set("monosaw_amp",0.0)
  osc.event=function(path,args,from)
    if path=="lpf" then
      self.lpffreq=args[2]
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
    params:delta("monosaw_lpflfo",d)
  elseif k==2 then
    params:delta("monosaw_lpfmin",d)
  elseif k==3 then
    params:delta("monosaw_lpfadj",d)
  end
end

function Monosaw:draw()
  screen.aa(2)

  local eye={
    ltr=true,
    edge={40,40},
  size={72,31}}

  local brightness=10
  local irisSize=14
  local blinkState=util.explin(20,2000,2.8,0,self.lpffreq)
  local volume=100

  irisX=eye.edge[1]+util.round(((eye.ltr and 1 or-1)*eye.size[1])/2+(irisSize/1.5))
  irisY=eye.edge[2]-util.round(eye.size[2]*0.6)

  -- NOTE: pls disregard about these magics..
  local magic_four=util.linlin(0,3,0,16,blinkState)
  local magic_six=util.linlin(0,3,0,8,blinkState)

  screen.move(eye.edge[1],eye.edge[2])
  screen.level(util.round(util.linlin(1,100,0,13,volume)))
  screen.curve(
    util.round(eye.edge[1]+((eye.ltr and 0.3 or-0.3)*eye.size[1])),
    util.round(eye.edge[2]-(eye.size[2]*0.75)+magic_four),
    util.round(eye.edge[1]+((eye.ltr and 0.75 or-0.75)*eye.size[1])),
    util.round(eye.edge[2]-(eye.size[2]*0.65)+magic_four),
    eye.edge[1]+((eye.ltr and 1 or-1)*eye.size[1]),
  eye.edge[2])
  screen.curve(
    util.round(eye.edge[1]+((eye.ltr and 1 or-1)*eye.size[1])+((eye.ltr and-0.65 or 0.65)*eye.size[1])),
    util.round(eye.edge[2]+(eye.size[2]*0.5625)-magic_six),
    util.round(eye.edge[1]+((eye.ltr and 1 or-1)*eye.size[1])+((eye.ltr and-0.875 or 0.875)*eye.size[1])),
    util.round(eye.edge[2]-(eye.size[2]*0.125)+blinkState-magic_six),
    eye.edge[1],
  eye.edge[2])
  screen.stroke()

  screen.level(util.round(util.linlin(1,100,0,util.linlin(0,3,8,4,blinkState),volume)))
  screen.arc(
    util.round(irisX-(irisSize*0.4))+blinkState,
    util.round(irisY+(irisSize*0.9))+blinkState,
    irisSize,
    -1*math.pi*util.linexp(0,3,0.22,0.01,blinkState),
  math.pi*util.linexp(0,3,0.4,0.15,blinkState))
  screen.move_rel(-1*util.linlin(0,3,0.01,20,blinkState),0)
  screen.arc(
    util.round(irisX-(irisSize*0.4))+blinkState,
    util.round(irisY+(irisSize*0.9))+blinkState,
    irisSize,
    math.pi*util.linexp(0,3,0.65,0.9,blinkState),
  math.pi*util.linexp(0,3,1.22,1.00,blinkState))
  screen.stroke()

  if blinkState~=3 then
    screen.circle(
      irisX-util.round(irisSize*0.4)+blinkState-5,
      irisY+util.round(irisSize*0.85)+blinkState+5,
    util.linexp(0,3,util.linlin(1,100,6,3,brightness),3,blinkState))
    screen.fill()
  end
end

return Monosaw
