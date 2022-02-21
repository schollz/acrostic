local AcrosticGrid={}
local s=require("sequins")
local musicutil=require("musicutil")

function AcrosticGrid:new(args)
  local m=setmetatable({},{
    __index=AcrosticGrid
  })
  local args=args==nil and {} or args

  m.note_on=args.note_on
  m.note_off=args.note_off
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  local grid=util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.toggles={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    m.toggles[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
      m.toggles[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  m.fingers_on_notes=nil
  m.fingers_on_sequence=nil
  m.fingers_on_transpose=nil
  m.cur={0,0,0,false}
  m.seq=s{m.cur}
  m.seqdiv=s{1/16}
  m.scale=musicutil.generate_scale (0,'major',90)
  m.transpose_options={1,-1,2,-2}
  m.division_options={1/16,1/12,1/8,1/6,1/4,1/2,1,2,4,8}

  return m
end

function AcrosticGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function AcrosticGrid:key_press(row,col,on)
  if on then
    self.pressed_buttons[row..","..col]=1
  else
    self.pressed_buttons[row..","..col]=nil
  end
  if not on then
    if self.fingers_on_notes~=nil and self.fingers_on_notes[1]==row and self.fingers_on_notes[2]==col then
      self.fingers_on_notes=nil
    end
    if self.fingers_on_sequence~=nil and self.fingers_on_sequence[1]==row and self.fingers_on_sequence[2]==col then
      self.fingers_on_sequence=nil
    end
    if self.fingers_on_transpose~=nil and self.fingers_on_transpose[1]==row and self.fingers_on_transpose[2]==col then
      self.fingers_on_transpose=nil
    end
    do return end
  end
  if row<=6 then
    if self.fingers_on_notes~=nil then
      self:toggle_note_from_to(self.fingers_on_notes[1],self.fingers_on_notes[2],row,col)
    else
      self.fingers_on_notes={row,col}
      self:toggle_note(row,col)
    end
  elseif row==7 then
    if self.fingers_on_sequence~=nil then
      self:toggle_note_from_to(self.fingers_on_sequence[1],self.fingers_on_sequence[2],row,col,true)
    else
      self.fingers_on_sequence={row,col}
      self:toggle_note(row,col)
    end
  elseif row==8 then
    if self.fingers_on_transpose~=nil then
      self:toggle_note_from_to(self.fingers_on_transpose[1],self.fingers_on_transpose[2],row,col)
    else
      self.fingers_on_transpose={row,col}
      self:toggle_note(row,col)
    end
  end
end

function AcrosticGrid:emit()
  self.cur=self.seq()
  local row=self.cur[2]
  local col=self.cur[1]
  local gate=self.cur[3]
  local div=self.seqdiv()
  if gate==0 or gate==2 then
    -- do note off
    if self.note_off~=nil then
      self.note_off(div)
    end
  end
  if row<1 or row>6 or gate==0 then
    do return end
  end
  if self.note_on~=nil then
    local transpose_note=0
    if self.toggles[8][col]>0 then
      transpose_note=self.transpose_options[self.toggles[8][col]]*2
      if transpose_note==0 then
        transpose_note=nil
      end
    end
    if row~=nil and transpose_note~=nil then
      self.note_on(col,row,gate==2,transpose_note,div)
    end
  end
end

function AcrosticGrid:update_sequence()
  local step_length=clock.get_beat_sec()/4
  local seq={}
  local seqdiv={}
  for col=1,16 do
    if self.toggles[7][col]>0 then
      --               col,row,gate
      local found_note={col,0,0}
      for row=1,6 do
        if self.toggles[row][col]>0 then
          -- this is a step in the sequence
          found_note={col,row,self.toggles[row][col]} -- 2=gate + note off, 1=sustain, 0=note off
        end
      end
      table.insert(seq,found_note)
      table.insert(seqdiv,self.division_options[self.toggles[7][col]])
    end
  end
  if next(seq)==nil then
    seq={{0,0,0,false}}
    seqdiv={1/16}
  end
  self.seq:settable(seq)
  self.seqdiv:settable(seqdiv)
  for i=1,#seq-1 do
    self.seqdiv() -- make sure the divisions are one ahead  
  end
end

function AcrosticGrid:toggle_note(row,col)
  if row==8 then
    self.toggles[row][col]=self.toggles[row][col]+1
    if self.toggles[row][col]>#self.transpose_options then
      self.toggles[row][col]=0
    end
  elseif row<7 then
    for r=1,6 do
      if r~=row then
        self.toggles[r][col]=0
      end
    end
    if self.toggles[row][col]==0 then
      self.toggles[row][col]=2
    elseif self.toggles[row][col]==2 then
      self.toggles[row][col]=1
    else
      self.toggles[row][col]=0
    end
    self:update_sequence()
  elseif row==7 then
    self.toggles[row][col]=self.toggles[row][col]+1
    if self.toggles[row][col]>#self.division_options then
      self.toggles[row][col]=0
    end
    self:update_sequence()
  end
end

function AcrosticGrid:toggle_note_from_to(row1,col1,row2,col2,toggle_note_from)
  if col2==col1 then
    do return end
  end
  local m=(row2-row1)/(col2-col1)
  local b=row2-(m*col2)
  local startcol=col1+1
  if toggle_note_from~=nil and toggle_note_from==true then
    startcol=col1
  end
  if row1==7 and row2==7 then
    -- special case: two fingers on sequence will clear everything
    -- sequences must be entered one at a time to change divisions
    for col=1,16 do
      self.toggles[7][col]=0
    end
  end
  for col=startcol,col2 do
    row=util.round(m*col+b)
    self:toggle_note(row,col)
  end
end

function AcrosticGrid:get_visual()
  -- clear visual / show toggles
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-2
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
      if row<=6 then
        self.visual[row][col]=self.toggles[row][col]*5
      elseif row==7 then
        self.visual[row][col]=self.toggles[row][col]*1
      elseif row==8 then
        self.visual[row][col]=self.toggles[row][col]*3
      end
    end
  end

  -- illuminate current played
  if self.cur[1]>0 then
    self.visual[7][self.cur[1]]=self.visual[7][self.cur[1]]+5
    if self.visual[7][self.cur[1]]>15 then
      self.visual[7][self.cur[1]]=15
    end
    if self.cur[2]>0 then
      for r=1,6 do
        if r~=self.cur[2] and self.visual[r][self.cur[1]]==0 then
          self.visual[r][self.cur[1]]=2
        end
      end
    end
  end
  -- -- illuminate currently pressed button
  -- for k,v in pairs(self.pressed_buttons) do
  --   local row,col=k:match("(%d+),(%d+)")
  --   row=tonumber(row)
  --   col=tonumber(col)
  -- end

  return self.visual
end

function AcrosticGrid:grid_redraw()
  local gd=self:get_visual()
  if self.g.rows==0 then
    do return end
  end
  self.g:all(0)
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

return AcrosticGrid
