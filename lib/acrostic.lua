include("acrostic/lib/table_addons")
include("acrostic/lib/utils")
if not string.find(package.cpath,"/home/we/dust/code/acrostic/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/acrostic/lib/?.so"
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
  return o
end

function Acrostic:init(o)
  self.loop_length=o.loop_length or 16

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
  params:add{type="number",id="sel_selection",name="sel_selection",min=1,max=4,default=4}
  params:hide("sel_selection")
  params:add{type="number",id="sel_chord",name="sel_chord",min=1,max=4,default=1}
  params:hide("sel_chord")
  params:add{type="number",id="current_chord",name="current_chord",min=1,max=4,default=4,wrap=true}
  params:hide("current_chord")
  params:add{type="number",id="sel_note",name="sel_note",min=1,max=6,default=1}
  params:hide("sel_note")
  params:add{type="number",id="sel_cut",name="sel_cut",min=1,max=6,default=1}
  params:hide("sel_cut")
  params:add{type="number",id="is_playing",name="is_playing",min=0,max=1,default=1,wrap=true}
  params:hide("is_playing")
  params:add_control("prob_note2","inter-note probability",controlspec.new(0,1,'lin',0.125/4,0.25,'',(0.125/4)/1))
  params:add_option("random_mode","random mode",{"off","on"},1)

  for i=1,6 do
    params:add_group("loop "..i,9)
    params:add_control("level"..i,"level "..i,controlspec.new(0,1,'lin',0.01,0.5,'',0.01/1))
    params:add_control("rec_level"..i,"rec level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("rec_level"..i,function(x)
      softcut.rec_level(i,x)
    end)
    params:add_control("pre_level"..i,"pre level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("pre_level"..i,function(x)
      softcut.pre_level(i,x)
    end)
    params:add_control(i.."vol lfo amp","vol lfo amp",controlspec.new(0,1,"lin",0.01,0.25,"",0.01))
    params:add_control(i.."vol lfo period","vol lfo period",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."vol lfo offset","vol lfo offset",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."pan lfo amp","pan lfo amp",controlspec.new(0,1,"lin",0.01,0.2,"",0.01))
    params:add_control(i.."pan lfo period","pan lfo period",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."pan lfo offset","pan lfo offset",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
  end

  -- randomize lfo
  for i=1,6 do
    params:set(i.."vol lfo period",round_time_to_nearest_beat(math.random()*20+2))
    params:set(i.."vol lfo offset",round_time_to_nearest_beat(math.random()*60))
    params:set(i.."vol lfo amp",math.random()*0.25+0.1)
    params:set(i.."pan lfo amp",math.random()*0.6+0.2)
    params:set(i.."pan lfo period",round_time_to_nearest_beat(math.random()*20+2))
    params:set(i.."pan lfo offset",round_time_to_nearest_beat(math.random()*60))
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
  if self.lattice~=nil then
    self.lattice:destroy()
  end
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
  self.first_beat=true
  self.pattern_phrase=self.lattice:new_pattern{
    action=function(t)
      --print("phrase")
      if self.first_beat then
        self.first_beat=false
        for i=1,6 do
          softcut.position(i,self.o.minmax[i][2])
        end
      end
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

  self.pattern_measure=self.lattice:new_pattern{
    action=function(t)
      params:delta("current_chord",1)
      --print("current_chord",params:get("current_chord"))
      if params:get("is_playing")==1 then
        params:set("sel_chord",params:get("current_chord"))
        local note=self.matrix_final[params:get("sel_note")][params:get("sel_chord")]
        if note<10 then
          do return end
        end
        self:play_note(note)
        if params:get("random_mode")==2 then
          -- randomize next position
          params:delta("current_chord",math.random(0,2)-1)
          params:set("sel_chord",params:get("current_chord"))
          params:delta("sel_note",math.random(0,2)-1)
        end
        local sel_chord_next=params:get("sel_chord")+1
        if sel_chord_next>4 then
          sel_chord_next=1
        end
        self.next_note=self.matrix_final[params:get("sel_note")][sel_chord_next]
      end
      -- engine.bandpass_wet(1)
      -- engine.bandpass_rq(0.1)
      -- engine.bandpass_hz(MusicUtil.note_num_to_freq(note))
    end,
    division=1*self.loop_length/16,
  }
  self.pattern_measure_inter={}
  local scale=MusicUtil.generate_scale_of_length(params:get("root_note"),"Major",120)
  for i=1,3 do
    self.pattern_measure_inter[i]=self.lattice:new_pattern{
      action=function(t)
        if params:get("is_playing")==1 and math.random()<params:get("prob_note2") and self.next_note~=nil and self.last_note~=nil then
          print("next/last",self.next_note,self.last_note)
          local note=MusicUtil.snap_note_to_array(util.round(self.next_note/2+self.last_note/2),scale)
          print("play_note",note)
          if note<10 then
            do return end
          end
          self:play_note(note)
        end
      end,
      division=1*self.loop_length/16,
      delay=i*0.25,
    }
  end

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

  self:minimize_transposition(true)
  params:set("is_playing",1)
  self.softcut_stopped=false
  self.lattice:start()
end

function Acrostic:toggle_start(stop_all)
  if stop_all then
    print("stopping softcut")
    self.softcut_stopped=true
    for i=1,6 do
      softcut.level(i,0)
      softcut.rate(i,0)
      softcut.rec(i,0)
    end
    clock.run(function()
      clock.sleep(0.5)
      for i=1,6 do
        softcut.play(i,0)
        softcut.position(i,self.o.minmax[i][2])
      end
    end)
    params:set("is_playing",0)
  else
    params:delta("is_playing",1)
    if params:get("is_playing")==1 then
      if self.softcut_stopped then
        print("restting all")
        self.rec_queue={}
        self.softcut_stopped=false
        params:set("current_chord",4)
        self.lattice:hard_restart()
        for i=1,6 do
          softcut.play(i,1)
          softcut.rate(i,1)
        end
      end
    end
  end
end

function Acrostic:play_note(note)
  -- engine.mx_note_on(note,0.5,clock.get_beat_sec()*self.loop_length/4)
  print("play_note",note)
  local hz=MusicUtil.note_num_to_freq(note)
  if hz~=nil and hz>20 and hz<18000 then
    --engine.hz(hz)
  end
  local gate_length=clock.get_beat_sec()*50/100
  if crow~=nil then
    crow.output[2].action="{ to(0,0), to(5,"..gate_length.."), to(0,0) }"
    crow.output[2]()
    crow.output[1].volts=0.0372*note+0.527 --(note-24)/12
  end
  for name,m in pairs(self.midis) do
    if m.last_note~=nil then
      m.conn:note_off(m.last_note)
    end
    m.conn:note_on(note,64)
    self.midis[name].last_note=note
  end
  self.last_note=note

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
  audio.level_eng_cut(1)
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
  for i=1,6 do
    self:softcut_render(i)
  end
end

function Acrostic:softcut_render(i)
  softcut.render_buffer(self.o.minmax[i][1],self.o.minmax[i][2],self.loop_length*clock.get_beat_sec()+0.5,55)
end

function Acrostic:softcut_clear(i)
  self.recorded[i]=true
  clock.run(function()
    softcut.buffer_clear_region_channel(self.o.minmax[i][1],self.o.minmax[i][2]-0.5,self.loop_length*clock.get_beat_sec()+1,0.2,0)
    clock.sleep(0.5)
    self:softcut_render(i)
  end)
end

-- minimize_transposition transposes each chord for minimal distance
function Acrostic:minimize_transposition(changes)
  local chords={}
  local chord_notes={}
  for chord=1,4 do
    local notes=MusicUtil.generate_chord_roman(params:get("root_note"),"Major",self.available_chords[params:get("chord"..chord)])
    chord_notes[chord]=table.clone(notes)
    table.rotatex(notes,math.random(0,3))
    table.insert(chords,table.clone(notes))
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
  -- print("chords")
  -- table.print_matrix(chords)
  self.matrix_octave={}
  self.matrix_base={}
  for note=1,6 do 
    self.matrix_octave[note]={}
    self.matrix_base[note]={}
    for chord=1,4 do 
      self.matrix_octave[note][chord]=0
      self.matrix_base[note][chord]=chord_notes[chord][1]%12+36
    end
  end
  for chord=1,4 do
    for note,note_midi in ipairs(chords[chord]) do
      self.matrix_base[note+1][chord]=note_midi
    end
    local undone_note=#chords[chord]+2
    for i=undone_note,6 do
      self.matrix_base[i][chord]=chords[chord][math.random(1,#chords[chord])]+12
    end
  end
  -- print("self.matrix_base")
  -- table.print_matrix(self.matrix_base)
  self:update_final()
  -- print("update1")
  -- table.print_matrix(self.matrix_name)

  local averages={}
  for note=1,6 do
    for i=1,4 do
      self.matrix_base[note][i]=self.matrix_final[note][i]
      self.matrix_octave[note][i]=0
    end
    table.insert(averages,{table.average(self.matrix_final[note]),note})
  end
  table.sort(averages,function(a,b)
    return a[1]<b[1]
  end)
  local foo=table.clone(self.matrix_base)
  for i,v in ipairs(averages) do
	  if i==1 then 
		  for chord=1,4 do
        self.matrix_base[i][chord]=chord_notes[chord][1]%12+36
      end
	  else
      self.matrix_base[i]=foo[v[2]]
    end
  end
  self.matrix_octave[3]={12,12,12,12}
  self.matrix_octave[4]={12,12,12,12}
  self.matrix_octave[5]={12,12,12,12}
  self.matrix_octave[6]={24,24,24,24}
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
  self.matrix_final={}
  self.matrix_name={}
  for note=1,6 do
    self.matrix_final[note]={}
    self.matrix_name[note]={}
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
  if z==0 then
    do return end
  end
  if params:get("sel_selection")==1 then
    if k==2 then
      print("self:toggle_start",global_shift)
      self:toggle_start(global_shift)
    elseif k==3 then
      if math.random()<0.5 then
        self:minimize_transposition()
      else
        self:minimize_transposition(true)
      end
    end
  end
  if params:get("sel_selection")==2 then
    if global_shift then
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
    if global_shift then
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
  if params:get("sel_selection")==4 and k==2 then
    if global_shift then
      self:softcut_clear(params:get("sel_cut"))
    else
      local foo={}
      for i,v in ipairs(self.rec_queue) do
        if i<#self.rec_queue then
          table.insert(foo,v)
        end
      end
      self.rec_queue=foo
    end
  end
  if params:get("sel_selection")==4 and k==3 then
    if global_shift then
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
  print("queue_recording",i)
  if table.is_empty(self.rec_queue) then
    print("primed",i)
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
  if global_shift then
    if k==1 then
    elseif k==2 and (params:get("sel_selection")==2 or params:get("sel_selection")==3) then
      self:change_note(params:get("sel_note"),d)
    elseif k==3 and (params:get("sel_selection")==2 or params:get("sel_selection")==3) then
      self:change_chord(params:get("sel_chord"),d)
    elseif k==3 and params:get("sel_selection")==1 then
      params:delta("chord"..params:get("sel_chord"),d)
    end
    do return end
  end
  if k==1 then
    params:delta("sel_selection",math.sign(d))
  elseif k==2 then
    if params:get("sel_selection")==1 then
      params:delta("sel_chord",d)
    elseif params:get("sel_selection")==4 then
      params:delta("sel_cut",d)
    else
      params:delta("sel_note",d)
      params:set("sel_cut",params:get("sel_note"))
      params:set("sel_selection",3)
    end
  elseif k==3 then
    if params:get("sel_selection")==1 then

    elseif params:get("sel_selection")==4 then
      params:delta("level"..params:get("sel_cut"),d)
      self.show_level=10
    else
      params:delta("sel_chord",d)
      params:set("sel_selection",2)
    end
  end
end

function Acrostic:update()
  local ct=clock.get_beat_sec()*clock.get_beats()
  for i=1,6 do
    local pan=params:get(i.."pan lfo amp")*calculate_lfo(ct,params:get(i.."pan lfo period"),params:get(i.."pan lfo offset"))
    softcut.pan(i,util.clamp(pan,-1,1))

    local vol=params:get(i.."vol lfo amp")*calculate_lfo(ct,params:get(i.."vol lfo period"),params:get(i.."vol lfo offset"))
    vol=vol+params:get("level"..i)
    softcut.level(i,util.clamp(vol,0,1))
  end
end

function Acrostic:draw()
  screen.aa(0)
  -- draw the chords at the top
  -- block for the top
  if params:get("sel_selection")==1 then
    screen.level(15)
  else
    screen.level(5)
  end
  screen.rect(0,0,73,9)
  screen.fill()
  for i=1,4 do
    if params:get("sel_chord")==i then
      screen.level(0)
    else
      screen.level(3)
    end
    local chord=self.available_chords[params:get("chord"..i)]
    screen.move(8+(i-1)*19,7)
    screen.text_center(chord)
  end

  -- draw the note matrix
  screen.level(15)
  local highlight_col=params:get("sel_selection")==2
  local highlight_row=params:get("sel_selection")==3
  local high=params:get("sel_selection")==1 and 5 or 16
  screen.level(highlight_row and high or 4)
  screen.rect(2,11+9*(params:get("sel_note")-1),70,8)
  screen.stroke()

  for i=1,4 do
    local xx=8+(i-1)*19
    local yy=8
    local notes={}
    for j=1,6 do
      table.insert(notes,self.matrix_name[j][i])
    end
    if i==params:get("sel_chord") then
      screen.level(highlight_col and high or 4)
      screen.rect(xx-8+2,yy+2+1,16-2,53)
      screen.stroke()
    end
    for j,note in ipairs(notes) do
      if i==params:get("sel_chord") and j==params:get("sel_note") then
        screen.level(high)
        screen.rect(xx-7,yy+9*j-7,15,9)
        screen.fill()
        screen.level(0)
      else
        if highlight_col and i==params:get("sel_chord") then
          screen.level(high)
        elseif highlight_row and j==params:get("sel_note") then
          screen.level(high)
        else
          screen.level(5)
        end
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
      screen.rect(x-2,y-5,55,10)
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
    local pos=util.linlin(0,self.loop_length*clock.get_beat_sec(),1,53,self.o.pos[j])
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
  if self.show_level==nil then
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
  else
    self.show_level=self.show_level-1
    if self.show_level==0 then
      self.show_level=nil
    end
    foo=params:get("level"..params:get("sel_cut"))
  end
  screen.move(96,8)
  screen.level(15)
  screen.text_center(foo)

  screen.move(76,7)
  screen.level(15)
  if params:get("is_playing")==1 then
    screen.text(">")
  else
    screen.text("||")
  end
end

return Acrostic
