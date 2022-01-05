local NoteControl={}

function NoteControl:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  return o
end

function NoteControl:init(o)
  self.message=""
  self.message_level=0
end

function NoteControl:msg(s)
  self.message=s
  self.message_level=15
end

function NoteControl:enc(k,d)
  if k==2 then
    params:delta("internote_prob",d)
    self:msg("other-note prob: "..params:get("internote_prob")*100.."%")
  elseif k==3 then
    params:delta("gate_prob",d)
    self:msg("gate prob: "..params:get("gate_prob")*100.."%")
  end
end

function NoteControl:key(k,z)
  if k==2 then
    if z==1 then
      self.internote_prob=params:get("internote_prob")
      params:set("internote_prob",0)
      self.gate_prob=params:get("gate_prob")
      params:set("gate_prob",0)
    else
      if self.gate_prob~=nil then
        params:set("gate_prob",self.gate_prob)
      end
      self.gate_prob=nil
      if self.internote_prob~=nil then
        params:set("internote_prob",self.gate_prob)
      end
      self.internote_prob=nil
    end
  elseif k==3 then
    if z==1 then
      self.internote_prob=params:get("internote_prob")
      params:set("internote_prob",1)
      self.gate_prob=params:get("gate_prob")
      params:set("gate_prob",1)
    else
      if self.gate_prob~=nil then
        params:set("gate_prob",self.gate_prob)
      end
      self.gate_prob=nil
      if self.internote_prob~=nil then
        params:set("internote_prob",self.gate_prob)
      end
      self.internote_prob=nil
    end
  end
end

function NoteControl:draw()
  local a=params:get("gate_prob")
  local b=params:get("internote_prob")
  screen.clear()
  screen.aa(1)
  local x=0
  local max=15
  for i=1,a*max do
    screen.level(16-math.floor(i))
    local w=(max-i+1)^2/14+1
    screen.rect(x,1,w,64)
    screen.fill()
    x=x+w+2
  end
  screen.update()
  screen.blend_mode(4)
  local y=53
  local max=10
  for i=1,b*max do
    screen.level(16-math.floor(i))
    local h=(max-i+1)^2/14+1
    screen.rect(1,y,128,h)
    screen.fill()
    y=y-h-2
  end
  screen.update()
  screen.blend_mode(0)
  screen.aa(0)

  if self.message_level>0 and self.message~="" then
    self.message_level=self.message_level-1
    screen.aa(0)
    screen.move(96,8)
    screen.level(self.message_level)
    screen.text_center(self.message)
  end
end

return NoteControl
