include("acrostic/lib/table_addons")
local MusicUtil=require("acrostic/lib/musicutil")
local lattice_=require("lattice")
local s=require("sequins")

local Acrostic={}

function Acrostic:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  -- setup lattice
  self.lattice=lattice_:new()

  -- setup midi
  self.midis={}
  for _,dev in pairs(midi.devices) do
    local name=string.lower(dev.name)
    name=name:gsub("-","")
    print("connected to "..name)
    self.midis[name]={last_note=nil}
    self.midis[name].conn=midi.connect(dev.port)
  end

  -- setup parameters
  params:add{type="number",id="root_note",name="root note",min=0,max=127,default=48,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
  params:set_action("root_note",function(x)
    self:update_chords()
  end)
  self.available_chords={"I","ii","iii","IV","V","vi","VII","i","II","III","iv","v","VI","vii"}
  local available_chords_default={6,4,1,5}
  for i=1,4 do
    params:add_option("chord"..i,"chord "..i,self.available_chords,available_chords_default[i])
    params:set_action("chord"..i,function(x)
      self:update_chords()
    end)
  end

  -- setup matrix
  self.matrix_base={}
  self.matrix_octave={}
  self.matrix_final={}
  self.matrix_name={}
  for note=1,6 do
    for chord=1,4 do
      self.matrix_base[note][chord]=0
      self.matrix_octave[note][chord]=0
      self.matrix_final[note][chord]=0
      self.matrix_name[note][chord]=""
    end
  end
  self:update_chords()

  -- setup selections
  params:add{type="number",id="sel_selection",name="sel_selection",min=1,max=3,default=2}
  params:hide("sel_selection")
  params:add{type="number",id="sel_chordprogression",name="sel_chordprogression",min=1,max=4,default=1}
  params:hide("sel_chordprogression")
  params:add{type="number",id="sel_chord",name="sel_chord",min=1,max=4,default=1}
  params:hide("sel_chord")
  params:add{type="number",id="sel_note",name="sel_note",min=1,max=6,default=1}
  params:hide("sel_note")

  -- setup the waveforms
  self.waveforms={}
  for i=1,6 do
    self.waveforms[i]={}
    for j=1,55 do
      self.waveforms[i][j]=0
    end
  end
  softcut.event_render(function(ch,start,sec_per_sample,samples)
    self.waveforms[ch]=samples
  end)

  return o
end

function Acrostic:update_chords()
  for chord=1,4 do
    local chord_notes=MusicUtil.generate_chord_roman(params:get("root_note"),"Major",params:get("chord"..chord))
    local notes={}
    for _,note in ipairs(chord_notes) do
      table.insert(notes,note)
    end
    for _,note in ipairs(chord_notes) do
      if #notes<6 then
        table.insert(notes,note+12)
      end
    end
    for _,note in ipairs(chord_notes) do
      if #notes<6 then
        table.insert(notes,note+24)
      end
    end
    for i,note in ipairs(notes) do
      self.matrix_base[i][chord]=note
    end
  end
  self:update_final()
end

function Acrostic:update_final()
  for note=1,6 do
    for chord=1,4 do
      self.matrix_final[note][chord]=self.matrix_base[note][chord]+self.matrix_octave[note][chord]
      self.matrix_name[note][chord]=MusicUtil.note_num_to_name(self.matrix_final[note][chord],true)
    end
  end
end

-- change_octave changes the octave for all four columns
function Acrostic:change_octave(row,d)
  for chord=1,4 do
    self.matrix_octave[row][chord]=self.matrix_octave[row][chord]+d*12
  end

  self:update_final()
end

-- change_chord rotates the chords
function Acrostic:change_chord(chord,d)
  local t={}
  for note=1,6 do
    table.insert(t,self.matrix_base[note][chord])
  end

  table.rotate(t,d)
  for note=1,6 do
    self.matrix_base[note][chord]=t[note]
  end

  self:update_final()
end

function Acrostic:enc(k,d)
  if k==1 then
    if params:get("sel_selection")==1 then
      params:delta("sel_chordprogression",d)
    end
  elseif k==2 then
    params:delta("sel_selection",d)
  elseif k==3 then
    if params:get("sel_selection")==1 then
      params:delta("chord"..params:get("sel_chordprogression"),d)
    elseif params:get("sel_selection")==2 then
      self:change_chord(params:get("sel_chord"),d)
    elseif params:get("sel_selection")==3 then
      self:change_octave(params:get("sel_note"),d)
    end
  end
end

function Acrostic:draw()

  -- draw the chords at the top
  -- block for the top
  if params:get("sel_selection")==1 then
    screen.level(15)
    screen.rect(0,0,70,9)
    screen.fill()
  end
  for i=1,4 do
    if params:get("sel_selection")==1 then
      if self.sel_chord==i then
        screen.level(0)
      else
        screen.level(3)
      end
    else
      screen.level(15)
    end
    local chord=self.available_chords[params:get("chord"..i)]
    screen.move(8+(i-1)*19,7)
    screen.text_center(chord)
  end

  -- draw the note matrix
  screen.level(15)
  local highlight_col=params:get("sel_selection")==2
  local highlight_row=params:get("sel_selection")==3
  if highlight_row then
    screen.level(15)
    screen.rect(1,10+9*0,71,9)
    screen.fill()
  end
  for i=1,4 do
    local xx=8+(i-1)*19
    local yy=8
    local notes={}
    for j=1,6 do
      table.insert(notes,self.matrix_name[j][i])
    end
    if i==params:get("sel_note") and highlight_col then
      screen.level(15)
      screen.rect(xx-8,yy+2,16,64)
      screen.fill()
    else
      screen.level(15)
    end
    for j,note in ipairs(notes) do
      if highlight_row and j==params:get("sel_note") then
        screen.level(0)
      elseif highlight_col and i==params:get("sel_chord") then
        screen.level(0)
      else
        screen.level(15)
      end
      screen.move(xx,yy+9*j)
      screen.text_center(note)
    end
  end

  -- draw the waveforms
  for j=1,6 do
    local y=5+9*j
    local levels={12,5,2,1}
    for sign=-1,1,2 do
      for kk=4,1,-1 do
        screen.level(levels[kk])
        screen.move(11+(4-1)*19+8,y)
        for i,sample in ipairs(self.waveforms[j]) do
          local xx=11+(4-1)*19+8+(i-1)
          local yy=y+util.linlin(-1,1,-1*kk,kk,sign*math.abs(sample))
          screen.line(xx,yy)
          screen.stroke()
          screen.move(xx,yy)
        end
      end
    end
  end
end

return Acrostic
