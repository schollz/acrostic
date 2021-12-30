include("acrostic/lib/table_addons")
if not string.find(package.cpath,"/home/we/dust/code/o-o-o/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/o-o-o/lib/?.so"
end
local json=require("cjson")
local MusicUtil=require("musicutil")
local lattice_=require("lattice")
local s=require("sequins")

local Acrostic={}

function Acrostic:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self

  self.shift=false
  self.loop_length=8

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
    self.matrix_base[note]={}
    self.matrix_octave[note]={}
    self.matrix_final[note]={}
    self.matrix_name[note]={}
    for chord=1,4 do
      self.matrix_base[note][chord]=0
      self.matrix_octave[note][chord]=0
      self.matrix_final[note][chord]=0
      self.matrix_name[note][chord]=""
    end
  end

  -- setup selections
  params:add{type="number",id="sel_selection",name="sel_selection",min=1,max=4,default=1}
  params:hide("sel_selection")
  params:add{type="number",id="sel_chordprogression",name="sel_chordprogression",min=1,max=4,default=1}
  params:hide("sel_chordprogression")
  params:add{type="number",id="sel_chord",name="sel_chord",min=1,max=4,default=1}
  params:hide("sel_chord")
  params:add{type="number",id="sel_note",name="sel_note",min=1,max=6,default=1}
  params:hide("sel_note")
  params:add{type="number",id="sel_cut",name="sel_cut",min=1,max=6,default=1}
  params:hide("sel_cut")

  for i=1,6 do
    params:add_control("level"..i,"level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("level"..i,function(x)
      softcut.level(i,x)
    end)
    params:add_control("rec_level"..i,"rec level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("rec_level"..i,function(x)
      softcut.rec_level(i,x)
    end)
    params:add_control("pre_level"..i,"pre level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("pre_level"..i,function(x)
      softcut.pre_level(i,x)
    end)
  end

  -- setup the waveforms
  self.waveforms={}
  for i=1,6 do
    self.waveforms[i]={}
    for j=1,55 do
      self.waveforms[i][j]=0
    end
  end

  -- setup softcut
  self:softcut_init()

  -- setup lattices
  self.lattice=lattice_:new()
  self.rec_queue={}
  self.recorded={false,false,false,false,false,false}
  self.pattern_qn=self.lattice:new_pattern{
    action=function(t)
      if not table.is_empty(self.rec_queue) then
        local i=self.rec_queue[1].i
        self.rec_queue[1].left=self.rec_queue[1].left-1
        if #self.rec_queue>1 then
          if self.rec_queue[1].left<self.loop_length and self.rec_queue[2].primed==false then
            softcut.rec_once(self.rec_queue[2].i)
            self.rec_queue[2].left=self.loop_length
          end
        end
        if self.rec_queue[1].left>0 then
          self.recorded[i]=true
          self:softcut_render(i)
        else
          -- pop the first element
          self:softcut_render(self.rec_queue[1].i)
          clock.run(function()
            local ii=self.rec_queue[1].i
            clock.sleep(0.2)
            self:softcut_render(ii)
            clock.sleep(1.2)
            self:softcut_render(ii)
          end)
          table.remove(self.rec_queue,1)
        end
      end
    end,
    division=1/4,
  }
  self.pattern_phrase=self.lattice:new_pattern{
    action=function(t)
      print("phrase")
      if not table.is_empty(self.rec_queue) then
        if params:get("sel_note")~=self.rec_queue[1].i then
          if (self.rec_queue[1].left~=nil and self.rec_queue[1].left>1) or self.rec_queue[1].left==nil then
            params:set("sel_note",self.rec_queue[1].i)
          end
        end
      end
      -- if math.random()<0.25 then
      --   self.softcut_goto0()
      -- end
    end,
    division=4*self.loop_length/16,
  }
  self.current_chord=4
  self.pattern_measure=self.lattice:new_pattern{
    action=function(t)
      self.current_chord=self.current_chord+1
      if self.current_chord>4 then
        self.current_chord=1
      end
      local note=self.matrix_final[params:get("sel_note")][self.current_chord]
      -- print(note)
      -- engine.bandpass_wet(1)
      -- engine.bandpass_rq(0.1)
      -- engine.bandpass_hz(MusicUtil.note_num_to_freq(note))
    end,
    division=1*self.loop_length/16,
  }

  params:bang()

  params.action_write=function(filename,name)
    print("write",filename,name)
    for i=1,6 do
      local fname=filename.."_"..i..".wav"
      print("saving "..fname)
      softcut.buffer_write_mono(fname,self.o.minmax[i][2],self.loop_length*clock.get_beat_sec()+2,self.o.minmax[i][1])
    end
    local fname=filename..".json"
    local data={}
    local to_save={"loop_length","recorded","matrix_octave","matrix_base","matrix_final","matrix_name"}
    for _,key in ipairs(to_save) do
      data[key]=json.encode(self[key])
    end
    local file=io.open(fname,"w+")
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
  end
  params.action_read=function(filename,silent)
    print("read",filename,silent)
    for i=1,6 do
      local fname=filename.."_"..i..".wav"
      if util.file_exists(fname) then
        print("loading "..fname)
        softcut.buffer_read_mono(fname,0,self.o.minmax[i][2],-1,1,self.o.minmax[i][1],0,1)
        self:softcut_render(i)
      end
    end
    local fname=filename..".json"
    local f=io.open(fname,"rb")
    local content=f:read("*all")
    f:close()
    local data=json.decode(content)
    for k,v in pairs(data) do
      self[k]=json.decode(v)
    end
    self:softcut_init()
    params:bang()
  end
  self.lattice:start()
  return o
end

function Acrostic:softcut_goto0()
  print("syncing samples")
  for i=1,6 do
    softcut.position(i,self.o.minmax[i][2])
  end
end

function Acrostic:softcut_init()
  self.o={}
  self.o.minmax={
    {1,1,80},
    {1,82,161},
    {1,163,243},
    {2,1,80},
    {2,82,161},
    {2,163,243},
  }
  self.o.pos={}

  softcut.reset()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(0)
  audio.level_tape_cut(1)
  for i=1,6 do
    softcut.enable(i,1)

    softcut.level_input_cut(1,i,0.5)
    softcut.level_input_cut(2,i,0.5)

    softcut.buffer(i,self.o.minmax[i][1])
    softcut.level(i,1.0)
    softcut.pan(i,0)
    softcut.rate(i,1)
    softcut.loop(i,1)
    softcut.loop_start(i,self.o.minmax[i][2])
    softcut.loop_end(i,self.o.minmax[i][2]+self.loop_length*clock.get_beat_sec())
    softcut.rec(i,0)

    softcut.level_slew_time(i,0.2)
    softcut.rate_slew_time(i,0.2)
    softcut.recpre_slew_time(i,0.1)
    softcut.fade_time(i,0.2)

    softcut.rec_level(i,params:get("rec_level"..i))
    softcut.pre_level(i,params:get("pre_level"..i))
    softcut.phase_quant(i,0.025)

    softcut.post_filter_dry(i,0.0)
    softcut.post_filter_lp(i,1.0)
    softcut.post_filter_rq(i,1.0)
    softcut.post_filter_fc(i,20100)

    softcut.pre_filter_dry(i,1.0)
    softcut.pre_filter_lp(i,1.0)
    softcut.pre_filter_rq(i,1.0)
    softcut.pre_filter_fc(i,20100)

    softcut.position(i,self.o.minmax[i][2])
    softcut.play(i,1)
    self.o.pos[i]=0
  end
  softcut.event_render(function(ch,start,sec_per_sample,samples)
    for i,v in ipairs(self.o.minmax) do
      if v[1]==math.floor(ch) and math.abs(v[2]-start)<2 then
        self.waveforms[i]=samples
      end
    end
  end)
  softcut.event_phase(function(i,pos)
    self.o.pos[i]=pos-self.o.minmax[i][2]
  end)
  softcut.poll_start_phase()
end

function Acrostic:softcut_render(i)
  softcut.render_buffer(self.o.minmax[i][1],self.o.minmax[i][2],self.loop_length*clock.get_beat_sec()+0.5,55)
end

function Acrostic:softcut_clear(i)
  self.recorded[i]=true
  softcut.level(i,0)
  clock.run(function()
    clock.sleep(0.2)
    softcut.buffer_clear_region_channel(self.o.minmax[i][1],self.o.minmax[i][2],self.loop_length*clock.get_beat_sec()+1,0,0)
    clock.sleep(0.2)
    softcut.level(i,params:get("level"..i))
    self:softcut_render(i)
  end)
end

-- minimize_transposition transposes each chord for minimal distance
function Acrostic:minimize_transposition(changes)
  local chords={}
  for chord=1,4 do
    local notes=MusicUtil.generate_chord_roman(params:get("root_note"),"Major",self.available_chords[params:get("chord"..chord)])
    table.insert(chords,notes)
  end
  local chords_basic=table.clone(chords)
  for i,chord in ipairs(chords) do
    if i>1 then
      chords[i]=table.smallest_modded_rot(current_chord,chord,12)
    end
    while table.average(chords[i])-params:get("root_note")>12 do
      for j,_ in ipairs(chords[i]) do
        chords[i][j]=chords[i][j]-12
      end
    end
    while table.average(chords[i])-params:get("root_note")<-12 do
      for j,_ in ipairs(chords[i]) do
        chords[i][j]=chords[i][j]+12
      end
    end
    current_chord=chords[i]
  end
  if changes then
    chords=table.minimize_row_changes(chords)
  end
  table.print_matrix(chords)
  for chord=1,4 do
    for i=1,3 do
      local notes={i,i+3}
      for ii,note in ipairs(notes) do
        self.matrix_octave[note][chord]=(ii-1)*12
        self.matrix_base[note][chord]=chords[chord][i]
      end
    end
  end
  for i=1,4 do
    self.matrix_base[6][i]=(chords_basic[i][1]%12)+12
  end
  self:update_final()
end

function Acrostic:update_chords()
  for chord=1,4 do
    local chord_notes=MusicUtil.generate_chord_roman(params:get("root_note"),"Major",self.available_chords[params:get("chord"..chord)])
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
  d=d*-1
  local t={}
  for note=1,6 do
    table.insert(t,self.matrix_final[note][chord])
  end

  table.rotatex(t,d)
  for note=1,6 do
    self.matrix_base[note][chord]=t[note]
    self.matrix_octave[note][chord]=0
  end

  self:update_final()
end

-- change_chord rotates the notes
function Acrostic:change_note(note,d)
  d=d*-1
  local t={}
  for chord=1,4 do
    table.insert(t,self.matrix_final[note][chord])
  end

  table.rotatex(t,d)
  for chord=1,4 do
    self.matrix_base[note][chord]=t[chord]
    self.matrix_octave[note][chord]=0
  end

  self:update_final()
end

function Acrostic:key(k,z)
  if k==1 then
    self.shift=z==1
  end
  if z==0 then
    do return end
  end
  if self.shift and k==2 then
    self:softcut_clear(params:get("sel_cut"))
  end
  if params:get("sel_selection")==1 then
    if k==2 then
      self:minimize_transposition()
    elseif k==3 then
      self:minimize_transposition(true)
    end
  end
  if params:get("sel_selection")==2 then
    if self.shift then
      if k==3 then
        local note=self.matrix_final[1][params:get("sel_chord")]
        local octave=(note-(note%12))/12
        for note=1,6 do
          self.matrix_octave[note][params:get("sel_chord")]=0
          self.matrix_base[note][params:get("sel_chord")]=(self.matrix_base[note][params:get("sel_chord")]%12)+octave*12
        end
      end
    else
      for note=1,6 do
        self.matrix_octave[note][params:get("sel_chord")]=self.matrix_octave[note][params:get("sel_chord")]+12*(k*2-5)
      end
    end
    self:update_final()
  end
  if params:get("sel_selection")==3 then
    if self.shift then
      if k==3 then
        local note=self.matrix_final[params:get("sel_note")][1]
        local octave=(note-(note%12))/12
        for chord=1,4 do
          self.matrix_octave[params:get("sel_note")][chord]=0
          self.matrix_base[params:get("sel_note")][chord]=(self.matrix_base[params:get("sel_note")][chord]%12)+octave*12
        end
      end
    else
      for chord=1,4 do
        self.matrix_octave[params:get("sel_note")][chord]=self.matrix_octave[params:get("sel_note")][chord]+12*(k*2-5)
      end
    end
    self:update_final()
  end
  if params:get("sel_selection")==4 and k==3 then
    if self.shift then
      for i=1,6 do
        if not self.recorded[i] then
          self:queue_recording(i)
        end
      end
    else
      self:queue_recording(params:get("sel_cut"))
    end
  end
end

function Acrostic:queue_recording(i)
  if table.is_empty(self.rec_queue) then
    table.insert(self.rec_queue,{i=i,left=self.loop_length+self:beats_left(i),primed=true})
    softcut.rec_once(i)
  else
    table.insert(self.rec_queue,{i=i,left=self.loop_length,rec=false,primed=false})
  end
end

function Acrostic:beats_left(i)
  return math.ceil(self.loop_length*(1-(self.o.pos[i]/(self.loop_length*clock.get_beat_sec()))))
end

function Acrostic:enc(k,d)
  if k==1 then
    params:delta("sel_selection",d)
  elseif k==2 then
    if params:get("sel_selection")<=2 then
      params:delta("sel_chord",d)
    elseif params:get("sel_selection")==3 then
      params:delta("sel_note",d)
      params:set("sel_cut",params:get("sel_note"))
    elseif params:get("sel_selection")==4 then
      params:delta("sel_cut",d)
    end
  elseif k==3 then
    if params:get("sel_selection")==1 then
      params:delta("chord"..params:get("sel_chord"),d)
    elseif params:get("sel_selection")==2 then
      self:change_chord(params:get("sel_chord"),d)
    elseif params:get("sel_selection")==3 then
      self:change_note(params:get("sel_note"),d)
    end
  end
end

function Acrostic:draw()
  -- draw the chords at the top
  -- block for the top
  if params:get("sel_selection")==1 then
    screen.level(15)
    screen.rect(0,0,73,9)
    screen.fill()
  end
  for i=1,4 do
    if params:get("sel_selection")==1 then
      if params:get("sel_chord")==i then
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
    screen.rect(1,10+9*(params:get("sel_note")-1),71,9)
    screen.fill()
  else
    screen.level(15)
    screen.rect(2,11+9*(params:get("sel_note")-1),70,8)
    screen.stroke()
  end
  for i=1,4 do
    local xx=8+(i-1)*19
    local yy=8
    local notes={}
    for j=1,6 do
      table.insert(notes,self.matrix_name[j][i])
    end
    if i==params:get("sel_chord") and highlight_col then
      screen.level(15)
      screen.rect(xx-8,yy+2,16,64)
      screen.fill()
    else
      screen.level(15)
    end
    for j,note in ipairs(notes) do
      local low=(self.current_chord==i and j==params:get("sel_note")) and 0 or 2
      local high=(self.current_chord==i and j==params:get("sel_note")) and 15 or 5
      if highlight_row and j==params:get("sel_note") then
        screen.level(low)
      elseif highlight_col and i==params:get("sel_chord") then
        screen.level(low)
      else
        screen.level(high)
      end
      screen.move(xx,yy+9*j)
      screen.text_center(note)
    end
  end

  -- draw the waveforms
  for j=1,6 do
    local x=11+(4-1)*19+8
    local y=5+9*j
    if params:get("sel_cut")==j and params:get("sel_selection")==4 then
      -- screen.rect()
      screen.level(15)
      screen.rect(x,y-5,55,10)
      screen.fill()
    end
    local levels={12,5,3,2,1}
    for sign=-1,1,2 do
      for kk=5,1,-1 do
        if params:get("sel_cut")==j and params:get("sel_selection")==4 then
          screen.level(0)
        else
          screen.level(levels[kk])
        end
        screen.move(x,y)
        for i,sample in ipairs(self.waveforms[j]) do
          local xx=x+(i-1)
          local yy=y+util.linlin(-1,1,-1*kk,kk,sign*math.abs(sample))
          screen.line(xx,yy)
          screen.stroke()
          screen.move(xx,yy)
        end
      end
    end
    -- draw waveform positions
    local pos=util.linlin(0,self.loop_length*clock.get_beat_sec(),0,53,self.o.pos[j])
    local xx=x+(pos-1)
    if params:get("sel_cut")==j and params:get("sel_selection")==4 then
      screen.level(0)
    else
      screen.level(5)
    end
    screen.move(xx,y+4)
    screen.line(xx,y-4)
    screen.stroke()
  end

  local foo=""
  if not table.is_empty(self.rec_queue) then
    if self.rec_queue[1].left<=self.loop_length then
      foo=foo.."r:"..self.rec_queue[1].i
      if #self.rec_queue>1 then
        foo=foo.." q:"
      end
    else
      foo=foo.."q:"..self.rec_queue[1].i.." "
    end
    for i,v in ipairs(self.rec_queue) do
      if i>1 then
        foo=foo..v.i.." "
      end
    end
  end
  screen.move(96,8)
  screen.level(15)
  screen.text_center(foo)

end

return Acrostic
