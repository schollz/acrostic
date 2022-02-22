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
  m.scale=musicutil.generate_scale (0,'major',90)
  m.transpose_options={0,1,-1,2,-2}
  m.repeat_options={4,6,8,10,12,14,16,24,32,48,64,72,96,128,2,1}
 
  return m
end

function AcrosticGrid:reset()
  self.seq:reset()
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
  if self.note_off~=nil then 
    self.note_off()
  end
  self.cur=self.seq()
  local row=self.cur[1]
  local col=self.cur[2]
  if row<1 or row>6 then
    do return end
  end
  if self.note_on~=nil then
    local transpose_note=nil
    if self.toggles[row][col]>0 then 
      transpose_note=self.transpose_options[self.toggles[row][col]]
    end
    if row~=nil and transpose_note~=nil then
      self.note_on(col,row,transpose_note)
    end
  end
end

function AcrosticGrid:update_sequence()
  local seq={}
  for col=1,16 do
    if self.toggles[8][col]>0 then
      local found_note={0,col}
      for row=1,6 do
        if self.toggles[row][col]>0 then
          found_note={row,col}
        end
      end
      for i=1,self.repeat_options[self.toggles[7][col]+1] do
        table.insert(seq,found_note)
      end
    end
  end
  if next(seq)==nil then
    seq={{0,0}}
  end
  self.seq:settable(seq)
end

function AcrosticGrid:toggle_note(row,col)
  if row==8 then
    self.toggles[row][col]=1-self.toggles[row][col]
  elseif row<=6 then
    local cur=self.toggles[row][col]
    local last=-1
    for r=1,6 do
      if r~=row then
        if self.toggles[r][col]>0 then
          last=self.toggles[r][col]
        end
        self.toggles[r][col]=0
      end
    end
    -- if last>-1 then
    --   self.toggles[row][col]=last
    -- else
    --   self.toggles[row][col]=self.toggles[row][col]+1
    -- end
    self.toggles[row][col]=self.toggles[row][col]+1
    if self.toggles[row][col]>#self.transpose_options then
      self.toggles[row][col]=0
    end
  elseif row==7 then
    if self.toggles[row][col]<=1 then
      self.toggles[row][col]=self.toggles[row][col]+1
    else
      self.toggles[row][col]=self.toggles[row][col]+2
    end
    if self.toggles[row][col]>15 then
      self.toggles[row][col]=0
    end
  end
  self:update_sequence()
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
    for col=col1,col2 do
      self.toggles[7][col]=0
    end
    self:update_sequence()
    do return end
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
        self.visual[row][col]=self.toggles[row][col]*3
        if self.visual[row][col]>15 then
          self.visual[row][col]=15
        end
      elseif row==7 then
        self.visual[row][col]=self.toggles[row][col]*1
      elseif row==8 then
        self.visual[row][col]=self.toggles[row][col]*5
      end
    end
  end

  -- illuminate current played
  if self.cur[2]>0 then
    self.visual[8][self.cur[2]]=self.visual[8][self.cur[2]]+5
    if self.visual[8][self.cur[2]]>15 then
      self.visual[8][self.cur[2]]=15
    end
    if self.cur[1]>0 then
        for r=1,6 do
          if r~=self.cur[1] then
            self.visual[r][self.cur[2]]=2
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
