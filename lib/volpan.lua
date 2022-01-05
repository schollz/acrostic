local VolPan={}

function VolPan:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  return o
end

function VolPan:init(o)
  self.a=o.acrostic
  self.sel=1
  self.shift=false
  self.message=""
  self.message_level=0
end

function VolPan:msg(s)
  self.message=s
  self.message_level=15
end

function VolPan:enc(k,d)
  local v={"vol adj","vol lfo amp","vol lfo period","pan adj","pan lfo amp","pan lfo period"}
  local vv=self.shift and v[k+3] or v[k]
  params:delta(self.sel..vv,d)
  self:msg(vv..": ",params:get(self.sel..vv))
end

function VolPan:key(k,z)
  if k==3 and z==1 then
    local sel=self.sel+1
    if sel>6 then
      sel=1
    end
    self.sel=sel
    self:msg("sample "..self.sel)
  elseif k==2 then
    self.shift=z==1
  end
end

function VolPan:draw()
  screen.aa(1)
  screen.blend_mode(1)
  local levels={2,4,6,8,10,12}
  for i=1,6 do
    local r=(7-i)*6
    local x=util.linlin(-1,1,1,128,self.a.pan[i])
    local y=util.linlin(0,1,64,1,self.a.vol[i])
    screen.circle(x,y,r)
    screen.level(levels[i])
    screen.fill()
    if self.sel==i then
      screen.circle(x,y,r+2)
      screen.level(15)
      screen.stroke()
    end
    screen.update()
  end
  screen.blend_mode(0)

  if self.message_level>0 and self.message~="" then
    self.message_level=self.message_level-1
    screen.aa(0)
    screen.move(96,8)
    screen.level(self.message_level)
    screen.text_center(self.message)
  end
end

return VolPan
