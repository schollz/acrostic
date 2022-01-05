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
end

function VolPan:enc(k,d)
    if self.shift then 
        if k==1 then 
            params:delta(self.sel.."pan adj",d)
        elseif k==2 then 
            params:delta(self.sel.."pan lfo amp",d)
        elseif k==3 then 
            params:delta(self.sel.."pan lfo period",d)
        end
    else    
        if k==1 then 
            params:delta(self.sel.."vol adj",d)
        elseif k==2 then 
            params:delta(self.sel.."vol lfo amp",d)
        elseif k==3 then 
            params:delta(self.sel.."vol lfo period",d)
        end
    end
end

function VolPan:key(k,z)
    if k==3 and z==1 then 
        local sel=self.sel+1 
        if sel>6 then 
            sel=1
        end
        self.sel=sel
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
end

return VolPan
