include("acrostic/lib/table_addons")
include("acrostic/lib/utils")
if not string.find(package.cpath,"/home/we/dust/code/acrostic/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/acrostic/lib/?.so"
end
local json=require("cjson")
local lattice_=include("acrostic/lib/lattice")
local s=require("sequins")
local MusicUtil=include("acrostic/lib/musicutil2")
local acrosticgrid_=include("acrostic/lib/acrosticgrid")
local has_rec_once=softcut.rec_once~=nil
local Acrostic={}

function Acrostic:new (o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  print("has rec_once: "..(has_rec_once and "yes" or "no"))
  return o
end

function Acrostic:init(o)
  self.pan={0,0,0,0,0,0}
  self.vol={0.5,0.5,0.5,0.5,0.5,0.5}
  self.message=""
  self.message_level=0
  self.debounce_chord_selection=0
  self.loop_length=16

  -- setup grid
  self.ag=acrosticgrid_:new{
    note_on=function(step,row,note_adjust)
      if self.scale_full==nil or self.matrix_final==nil then
        do return end
      end
      local chord=params:get("current_chord")
      local page=self.page
      if chord>4 then
        chord=chord-4
      end
      local note=self.matrix_final[page][row][chord]
      if row<=3 then
        if step<=4 then
          note=self.matrix_final[page][row+3][1]
        elseif step<=8 then
          note=self.matrix_final[page][row+3][2]
        elseif step<=12 then
          note=self.matrix_final[page][row+3][3]
        elseif step<=16 then
          note=self.matrix_final[page][row+3][4]
        end
      end
      -- local note=notes[row]
      if note_adjust~=0 and note_adjust~=nil then
        local idx=0
        for i,n in ipairs(self.scale_full) do
          if n==note then
            idx=i
          end
        end
        if idx+note_adjust>0 and idx+note_adjust<#self.scale_full then
          note=self.scale_full[idx+note_adjust]
        end
      end
      self:play_note(note,5)
      if self.grid_crow_dirty==true then
        self:update_grid_crow()
        self.grid_crow_dirty=false
      end
      crow.output[2](true)
    end,
    note_off=function()
      if self.had_origin5==nil then
        do return end
      end
      if self.grid_crow_dirty==true then
        self:update_grid_crow()
        self.grid_crow_dirty=false
      end
      crow.output[2](false)
    end
  }

  -- setup midi
  self.midis={}
  self.midi_devices={"none"}
  for _,dev in pairs(midi.devices) do
    local name=string.lower(dev.name)
    name=name:gsub("-","")
    if name~="virtual" then
      print("connected to "..name)
      table.insert(self.midi_devices,name)
      self.midis[name]={last_note=nil}
      self.midis[name].conn=midi.connect(dev.port)
    end
  end

  -- setup matrix
  self.matrix_base={}
  self.matrix_octave={}
  self.matrix_final={}
  self.matrix_name={}
  self.page=1
  for page=1,2 do
    self.matrix_base[page]={}
    self.matrix_octave[page]={}
    self.matrix_final[page]={}
    self.matrix_name[page]={}
    for note=1,6 do
      self.matrix_base[page][note]={}
      self.matrix_octave[page][note]={}
      self.matrix_final[page][note]={}
      self.matrix_name[page][note]={}
      for chord=1,4 do
        self.matrix_base[page][note][chord]=0
        self.matrix_octave[page][note][chord]=0
        self.matrix_final[page][note][chord]=0
        self.matrix_name[page][note][chord]=""
      end
    end
  end

  -- setup parameters
  params:add_group("chords",19)
  params:add_option("number_of_chords","num chords",{4,8},1)
  params:set_action("number_of_chords",function(x)
    self.do_update_beats=true
    self.do_set_cut_to_1=true
  end)
  params:add{type="number",id="root_note",name="root note",min=0,max=127,default=48,formatter=function(param) return MusicUtil.note_num_to_name(param:get(),true) end}
  self.scales_available={"Major","Minor"}
  params:add_option("scale","scale",self.scales_available,1)
  params:set_action("root_note",function(x)
    self.do_update_chords=true
  end)
  local basic_chords={"I","ii","iii","IV","V","vi","VII","i","II","III","iv","v","VI","vii"}
  self.available_chords={}
  for _,v in ipairs({"","7","6-9","+7"}) do
    for _,c in ipairs(basic_chords) do
      table.insert(self.available_chords,c..v)
    end
  end
  local available_chords_default={6,4,1,5}
  local chord_num=1
  for page=1,2 do
    for i=1,4 do
      params:add_option("chord"..page..i,"chord "..chord_num,self.available_chords,available_chords_default[i])
      params:set_action("chord"..page..i,function(x)
        self.do_update_chords=true
      end)
      params:add{type="number",id="beats"..page..i,name="beats "..chord_num,min=0,max=16,default=4}
      params:set_action("beats"..page..i,function(x)
        print("setting beats"..page..i.." to "..x)
        self.do_update_beats=true
        self.do_set_cut_to_1=true
      end)
      chord_num=chord_num+1
    end
  end
  self:update_beats(false)

  -- setup selections
  params:add{type="number",id="sel_selection",name="sel_selection",min=1,max=4,default=4}
  params:hide("sel_selection")
  local sel_selection_text={"chord","note","phrase","sampling"}
  params:set_action("sel_selection",function(x)
    self:msg(x..") "..sel_selection_text[x])
  end)
  params:add{type="number",id="sel_chord",name="sel_chord",min=1,max=4,default=1}
  params:hide("sel_chord")
  params:add{type="number",id="current_chord",name="current_chord",min=1,max=8,default=1,wrap=true}
  params:hide("current_chord")
  params:add{type="number",id="sel_note",name="sel_note",min=1,max=6,default=1}
  params:hide("sel_note")
  params:add{type="number",id="sel_cut",name="sel_cut",min=1,max=6,default=1}
  params:hide("sel_cut")
  params:add{type="number",id="is_playing",name="is_playing",min=0,max=1,default=1,wrap=true}
  params:hide("is_playing")

  params:add_group("notes",5)
  params:add_control("internote_prob","inter-note probability",controlspec.new(0,1,'lin',0.125/4,0.0,'',(0.125/4)/1))
  params:add_control("gate_prob","note gate probability",controlspec.new(0,1,'lin',0.125/4,1,'',(0.125/4)/1))
  params:add_option("melody_generator","melody generator",{"off","on"},1)
  params:add_option("random_mode","random mode",{"off","on"},1)
  params:add_option("do_reverse","reverse mode",{"off","on"},1)
  params:set_action("do_reverse",function(x)
    for i=1,6 do
      softcut.rate(i,x==1 and 1 or-1)
    end
    self.do_set_cut_to_1=true
  end)

  params:add_group("midi/grid/crow",15)
  params:add_option("midi_out","midi out",self.midi_devices,#self.midi_devices==1 and 1 or 2)
  params:add_option("grid_reset","grid reset every chord",{"yes","no"})
  params:add_option("crow_1_pitch","[1] pitch",{"normal","korg monotron"},1)
  local option_divisions={"1/32","1/16","1/8","1/4","1/2","1"}
  local option_divisions_num={1/32,1/16,1/8,1/4,1/2,1}
  params:add_control("crow_2_level","[2] level",controlspec.new(0,10,'lin',0.1,10,'volts',0.1/10))
  params:add_control("crow_2_attack","[2] attack",controlspec.new(0,10,'lin',0.01,1,'qn',0.01/10))
  params:add_control("crow_2_sustain","[2] sustain",controlspec.new(0,10,'lin',0.1,5,'volts',0.1/10))
  params:add_control("crow_2_decay","[2] decay",controlspec.new(0,10,'lin',0.01,1,'qn',0.01/10))
  params:add_control("crow_grid_attack","[2] attack (grid)",controlspec.new(0,4,'lin',0.01,0.2,'sn',0.01/4))
  params:add_control("crow_grid_sustain","[2] sustain (grid)",controlspec.new(0,10,'lin',0.1,6,'volts',0.1/10))
  params:add_control("crow_grid_decay","[2] decay (grid)",controlspec.new(0,4,'lin',0.01,0.5,'sn',0.01/4))
  params:add_control("crow_grid_release","[2] release (grid)",controlspec.new(0,4,'lin',0.01,0.2,'sn',0.01/4))
  for _,name in ipairs({"attack","sustain","decay","release"}) do
    params:set_action("crow_grid_"..name,function(x)
      self:update_grid_crow()
    end)
  end
  params:add_control("crow_3_volts","[3] volts",controlspec.new(0,10,'lin',0.1,1,'volts',0.1/10))
  local option_divisions={"1/32","1/16","1/8","1/4","1/2","1"}
  local option_divisions_num={1/32,1/16,1/8,1/4,1/2,1}
  params:add_option("crow 3 division","[3] division",option_divisions,3)
  params:set_action("crow 3 division",function(x)
    if self.pattern_clock_sync~=nil then
      self.pattern_clock_sync:set_division(option_divisions_num[x])
    end
  end)
  self.crow4_octaves={0.25,0.5,1,2,4}
  params:add_option("crow_4_octave","[4] octave",{"1/4","1/2","1","2","4"},2)
  params:add_control("crow_4_volts","[4] volts",controlspec.new(0,10,'lin',0.1,2,'volts',0.1/10))

  for i=1,6 do
    params:add_group("loop "..i,11)
    params:add_control("rec_level"..i,"rec level "..i,controlspec.new(0,1,'lin',0.01,1.0,'',0.01/1))
    params:set_action("rec_level"..i,function(x)
      if has_rec_once then
        softcut.rec_level(i,x)
      end
    end)
    params:add_control("pre_level"..i,"pre level "..i,controlspec.new(0,1,'lin',0.01,0.5,'',0.01/1))
    params:set_action("pre_level"..i,function(x)
      if has_rec_once then
        softcut.pre_level(i,x)
      end
    end)
    params:add_control(i.."vol adj","vol adj",controlspec.new(-1,1,"lin",0.1,0,"",0.1/2))
    params:add_control(i.."vol lfo amp","vol lfo amp",controlspec.new(0,1,"lin",0.01,0.25,"",0.01))
    params:add_control(i.."vol lfo period","vol lfo period",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."vol lfo offset","vol lfo offset",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."pan adj","pan adj",controlspec.new(-1,1,"lin",0.1,0,"",0.1/2))
    params:add_control(i.."pan lfo amp","pan lfo amp",controlspec.new(0,1,"lin",0.01,0.2,"",0.01))
    params:add_control(i.."pan lfo period","pan lfo period",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."pan lfo offset","pan lfo offset",controlspec.new(0,60,"lin",0,0,"s",0.1/60))
    params:add_control(i.."lpf","lpf",controlspec.new(40,20000,"exp",40,20000,"Hz",40/20000))
    params:set_action(i.."lpf",function(x)
      softcut.post_filter_fc(i,x)
    end)
  end

  -- randomize lfo
  for i=1,6 do
    -- params:set(i.."vol lfo period",round_time_to_nearest_beat(math.random()*10+10))
    -- params:set(i.."vol lfo offset",round_time_to_nearest_beat(math.random()*60))
    -- params:set(i.."vol lfo amp",math.random()*0.3+0.7)
    -- params:set(i.."pan lfo amp",math.random()*0.5+0.5)
    -- params:set(i.."pan lfo period",round_time_to_nearest_beat(math.random()*15+10))
    -- params:set(i.."pan lfo offset",round_time_to_nearest_beat(math.random()*60))
    -- oooooo v1.11.0
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
  self.recorded={false,false,false,false,false,false}
  self:softcut_init()

  -- setup lattices
  if self.lattice~=nil then
    self.lattice:destroy()
  end
  self.current_phrase=0
  self.current_chord_beat=0
  self.lattice=lattice_:new()
  self.rec_queue={}

  self.pattern_measure=self.lattice:new_pattern{
    action=function(t)
      local result=false
      local i=0
      while result==false do
        local last_phrase=self.current_phrase
        result=self:iterate_chord()
        i=i+1
        if i==8 then
          result=true
        end

        -- on the first chord of each time, clear the queue and prime the recording
        if self.current_phrase>last_phrase then
          print("bumped phrase")
          engine.sync()

          -- take care of queue
          if not table.is_empty(self.rec_queue) then
            if self.rec_queue[1].recording then
              clock.run(function()
                local i=self.rec_queue[1].i
                clock.sleep(0.2)
                self:softcut_render(i)
              end)
              print("dequeing "..self.rec_queue[1].i)
              if not has_rec_once then
                -- stop recording
                local i=self.rec_queue[1].i
                softcut.rec_level(i,0)
                clock.run(function()
                  clock.sleep(0.4)
                  softcut.rec(i,0)
                end)
              end
              table.remove(self.rec_queue,1)
            end
          end
          if not table.is_empty(self.rec_queue) then
            if self.rec_queue[1].primed then
              print("setting to record",self.rec_queue[1].i)
              params:set("sel_note",self.rec_queue[1].i)
              if not has_rec_once then
                -- do record
                clock.run(function()
                  local i=self.rec_queue[1].i
                  softcut.rec(i,1)
                  clock.sleep(0.1)
                  softcut.rec_level(i,params:get("rec_level"..i))
                end)
              end
              self.rec_queue[1].recording=true
            end
          end
        end

        -- on every note, check to see if another track needs to be primed
        if (params:get("current_chord")-1)%4+1==2 or (params:get("current_chord")-1)%4+1==3 then
          local do_prime=nil
          if (not table.is_empty(self.rec_queue)) and (not self.rec_queue[1].primed) then
            do_prime=1
          elseif #self.rec_queue>1 and (not self.rec_queue[2].primed) and self.rec_queue[1].recording then
            do_prime=2
          end
          if do_prime~=nil then
            self.rec_queue[do_prime].primed=true
            if has_rec_once then
              print("softcut.rec_once("..self.rec_queue[do_prime].i..")")
              softcut.rec_once(self.rec_queue[do_prime].i)
            else
              softcut.rec(self.rec_queue[do_prime].i,0)
              softcut.rec_level(self.rec_queue[do_prime].i,0)
            end
            self.recorded[self.rec_queue[do_prime].i]=true
          end
        end

      end

      -- play the resulting note
      self:iterate_note()

      -- if recording, update the image
      if not table.is_empty(self.rec_queue) and self.rec_queue[1].recording then
        self:softcut_render(self.rec_queue[1].i)
      end

      -- print out the current chord/beat
      local current_chord_mod4=(params:get("current_chord")-1)%4+1
      --print("current_chord:"..params:get("current_chord")," current beat: "..self.current_chord_beat.."/"..params:get("beats"..self.page..current_chord_mod4))
    end,
    division=1/4,
  }
  self.pattern_measure_inter={}
  local scale=MusicUtil.generate_scale_of_length(params:get("root_note"),params:get("scale"),120)
  self.scale_full=MusicUtil.generate_scale_of_length(params:get("root_note")%12,params:get("scale"),120)
  self.chord_full=MusicUtil.generate_chord_roman(params:get("root_note"),params:get("scale"),"I")
  for i=1,3 do
    self.pattern_measure_inter[i]=self.lattice:new_pattern{
      action=function(t)
        if params:get("is_playing")==1 and math.random()<(params:get("internote_prob")*params:get("sel_note")/6) and self.next_note~=nil and self.last_note~=nil then
          --print("next/last",self.next_note,self.last_note)
          local note=MusicUtil.snap_note_to_array(util.round(self.next_note/2+self.last_note/2)+math.random(-2,2),scale)
          if note<10 then
            do return end
          end
          self:play_note(note,2)
        end
      end,
      division=1/4,
      delay=i*0.25,
    }
  end
  self.pattern_upnote=self.lattice:new_pattern{
    action=function(t)
      if params:get("is_playing")==1 then
        local note=self:get_random_note(self:get_current_octave()+2)
        --print("up note: ",note)
        self:play_note(note,3)
      end
    end,
    division=1,
    delay=3/4,
  }
  self.pattern_midnote=self.lattice:new_pattern{
    action=function(t)
      if params:get("is_playing")==1 then
        local note=self:get_random_note(self:get_current_octave()+2)
        -- print("midnote: ",note)
        self:play_note(note,4)
      end
    end,
    division=1,
    delay=1/2,
  }
  -- setup the grid
  params:set("crow_grid_attack",0.1) -- initialize attack
  self.pattern_gridnote=self.lattice:new_pattern{
    action=function(t)
      self.ag:emit()
    end,
    division=1/64,
  }
  -- crow output 3 is for using a clock
  self.pattern_clock_sync=self.lattice:new_pattern{
    action=function(x)
      crow.output[3].action="{ to(0,0), to("..params:get("crow_3_volts")..","..(self.pattern_clock_sync.division*2*clock.get_beat_sec()).."), to(0,0) }"
      crow.output[3]()
    end,
    division=1/4,
  }

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
    self:toggle_start(true)
    print("read",filename,silent)
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
    clock.run(function()
      clock.sleep(0.5)
      for k,v in pairs(data) do
        self[k]=json.decode(v)
      end
      self:toggle_start()
    end)
    for i=1,6 do
      local fname=filename.."_"..i..".wav"
      if util.file_exists(fname) then
        print("loading "..fname)
        softcut.buffer_read_mono(fname,0,self.o.minmax[i][2],-1,1,self.o.minmax[i][1],0,1)
        self:softcut_render(i)
      end
    end
  end

  params:set("is_playing",1)
  self.softcut_stopped=false
  self.lattice:start()

end

function Acrostic:update_grid_crow()
  crow.output[2].action="adsr("..
  (clock.get_beat_sec()/4*params:get("crow_grid_attack"))..","..
  (clock.get_beat_sec()/4*params:get("crow_grid_decay"))..","..
  params:get("crow_grid_sustain")..","..
  (clock.get_beat_sec()/4*params:get("crow_grid_release"))..
  ",'linear')"
end

function Acrostic:iterate_chord()
  local current_chord_mod4=(params:get("current_chord")-1)%4+1
  self.current_chord_beat=self.current_chord_beat+1
  if self.current_chord_beat<=params:get("beats"..self.page..current_chord_mod4) then
    do return true end
  end
  -- iterate chord
  params:delta("current_chord",params:get("do_reverse")==1 and 1 or-1)
  self.current_chord_beat=1
  current_chord_mod4=(params:get("current_chord")-1)%4+1
  if params:get("is_playing")~=1 then
    do return true end
  end
  if (params:get("number_of_chords")==1 and current_chord_mod4==1) or (params:get("number_of_chords")==2 and params:get("current_chord")==1) then
    self.current_phrase=self.current_phrase+1
  end
  if self.debounce_chord_selection==0 then
    local page=self.page
    if params:get("number_of_chords")>1 then
      self.page=params:get("current_chord")>4 and 2 or 1
    else
      self.page=1
    end
    if page~=self.page then
      self:msg("page "..self.page)
    end
    if self.page==1 and current_chord_mod4==1 and self.do_set_cut_to_1~=nil and self.do_set_cut_to_1 then
      self.do_set_cut_to_1=nil
      print("resetting cuts")
      for i=1,6 do
        softcut.position(i,self.o.minmax[i][2])
      end
    end
    params:set("sel_chord",current_chord_mod4)

    if not table.is_empty(self.rec_queue) then
      if params:get("sel_note")~=self.rec_queue[1].i then
        if current_chord_mod4==1 then
          params:set("sel_note",self.rec_queue[1].i)
        end
      end
    end
  end
  if params:get("beats"..self.page..current_chord_mod4)==0 then
    do return false end
  end
  return true
end

function Acrostic:get_current_octave()
  local octave=0
  for chord=1,4 do
    octave=octave+(self.matrix_final[self.page][params:get("sel_note")][chord])
  end
  octave=util.round(octave/4/12-2.5)
  return octave
end

function Acrostic:get_random_note(octave)
  -- compute weights
  local notes={}
  local total_weight=0
  for page=1,2 do
    for note=1,6 do
      for chord=1,4 do
        local n=self.matrix_final[page][note][chord]%12
        if notes[n]==nil then
          notes[n]=0
        end
        notes[n]=notes[n]+1
        total_weight=total_weight+1
      end
    end
  end
  local r=math.random(0,total_weight-1)
  for n,w in pairs(notes) do
    if r<w then
      do return (octave and (n+12*octave) or n) end
    end
    r=r-w
  end
  print("should never get here")
end

function Acrostic:iterate_note()
  -- iterate note
  self.last_sel_chord=params:get("sel_chord")
  local note=self.matrix_final[self.page][params:get("sel_note")][params:get("sel_chord")]

  -- enunciate phrases
  local chord=params:get("current_chord")
  if chord>4 then
    chord=chord-4
  end
  local page=self.page
  local chord_roman=params:get("chord"..page..chord)
  if chord_roman~=self.last_chord_roman and note~=self.last_note then
    -- TODO: make this resetting optional
    if params:get("grid_reset")==1 then
      self.ag:reset()
    end
    self.gate_for_midi=true
    if self.had_origin5==nil then
      self.grid_crow_dirty=true
      crow.output[2].action="{ to(0,0), to("..params:get("crow_2_level")..
      ","..(clock.get_beat_sec()*params:get("crow_2_attack"))..
      "), to("..params:get("crow_2_sustain")..","..(clock.get_beat_sec()*params:get("crow_2_decay"))..") }"
      crow.output[2]()
    end
  end
  self.last_chord_roman=chord_roman
  self.last_note=note

  -- TODO: emit note from the grid

  -- play note
  self:play_note(note,1)
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
  self.next_note=self.matrix_final[self.page][params:get("sel_note")][sel_chord_next]
end

function Acrostic:set_page(p)
  if params:get("number_of_chords")==1 then
    self.page=1
    do return end
  end
  self.page=p
  self:msg("page "..p)
  self.debounce_chord_selection=20
end

function Acrostic:msg(s)
  self.message=s
  self.message_level=15
end

function Acrostic:toggle_start(stop_all)
  if stop_all then
    self:msg("stop all")
    print("stop all")
    self.softcut_stopped=true
    for i=1,6 do
      softcut.level(i,0)
      softcut.rate(i,0)
      softcut.rec(i,0)
    end
    clock.run(function()
      clock.sleep(0.5)
      print("playing all")
      for i=1,6 do
        softcut.play(i,0)
        softcut.position(i,self.o.minmax[i][2])
      end
    end)
    params:set("is_playing",0)
  else
    params:delta("is_playing",1)
    self.current_chord_beat=0
    if params:get("is_playing")==1 then
      clock.link.start()
      if self.softcut_stopped then
        self:msg("begin all")
        print("restting all")
        self.rec_queue={}
        self.softcut_stopped=false
        params:set("current_chord",params:get("do_reverse")==1 and 1 or 8)
        self.lattice:hard_restart()
        for i=1,6 do
          softcut.play(i,1)
          softcut.rate(i,params:get("do_reverse")==1 and 1 or-1)
        end
      else
        self:msg("begin phrase")
      end
    else
      self:msg("stop phrase")
      clock.link.stop()
    end
  end
  if params:get("is_playing")==0 then
    engine.amp(0)
  else
    engine.amp(params:get("monosaw_amp"))
  end
end

function Acrostic:play_note(note,origin)
  if origin==5 then
    self:trigger_note(note)
    self.had_origin5=5
    do return end
  end
  if self.had_origin5~=nil and self.had_origin5>0 then
    self.had_origin5=self.had_origin5-1
    if self.had_origin5>0 then
      self.had_origin5=nil
      do return end
    end
  end
  if math.random()>params:get("gate_prob") then
    do return end
  end

  local note_lfos={
    {math.random(20,30),math.random(0,60),1.0},
    {math.random(20,30),math.random(0,60),0.5},
    {math.random(20,30),math.random(0,60),0.6},
    {math.random(20,30),math.random(0,60),0.4},
  }
  local use_note_lfos=params:get("melody_generator")==2
  if use_note_lfos then
    local note_lfo=note_lfos[origin]
    local rmin=(calculate_lfo(clock.get_beats()*clock.get_beat_sec(),
    note_lfo[1],note_lfo[2])+1)*50 -- generates number 0-100
    rmin=math.floor(rmin*note_lfo[3])
    local rtarget=math.random(rmin,100)
    local r=math.random(0,100)
    if r>rtarget then
      print("skip note from origin "..origin)
      do return end
    end
  elseif not use_note_lfos and origin>1 then
    do return end
  end

  self:trigger_note(note)
end

function Acrostic:trigger_note(note)
  if note==nil then
    do return end
  end
  local hz=MusicUtil.note_num_to_freq(note)
  if hz~=nil and hz>20 and hz<18000 then
    engine.hz(hz)
  end
  if crow~=nil then
    if hz~=self.last_hz and (hz*self.crow4_octaves[params:get("crow_4_octave")]~=nil) then
      crow.output[4].action="oscillate("..(hz*self.crow4_octaves[params:get("crow_4_octave")])..","..params:get("crow_4_volts")..",'exponential')"
      crow.output[4]()
      self.last_hz=hz
    end
    if params:get("crow_1_pitch")==1 then
      crow.output[1].volts=(note-24)/12
    else
      crow.output[1].volts=0.0372*note+0.527 -- korg monotron!
    end
  end
  for name,m in pairs(self.midis) do
    if name==self.midi_devices[params:get("midi_out")] then
      if (m.last_note~=note and m.last_note~=nil) or (self.gate_for_midi==true) then
        m.conn:note_off(m.last_note)
        self.gate_for_midi=false
        m.conn:note_on(note,64)
        self.midis[name].last_note=note
      end
    end
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
    softcut.play(i,1)

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
    softcut.recpre_slew_time(i,0.4)
    softcut.fade_time(i,0.2)

    softcut.rec_level(i,has_rec_once and params:get("rec_level"..i) or 0)
    softcut.pre_level(i,has_rec_once and params:get("pre_level"..i) or 1.0)
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
    if i<7 then
      self.o.pos[i]=pos-self.o.minmax[i][2]
    end
  end)
  softcut.poll_start_phase()
  for i=1,6 do
    -- self:softcut_render(i)
    self:softcut_clear(i)
  end
end

function Acrostic:softcut_render(i)
  softcut.render_buffer(self.o.minmax[i][1],self.o.minmax[i][2],self.loop_length*clock.get_beat_sec()+0.5,55)
end

function Acrostic:softcut_clear(i)
  self.recorded[i]=false
  clock.run(function()
    softcut.buffer_clear_region_channel(self.o.minmax[i][1],self.o.minmax[i][2]-0.5,self.loop_length*clock.get_beat_sec()+1,0.2,0)
    clock.sleep(0.5)
    self:softcut_render(i)
    self:msg("cleared "..i)
  end)
end

function Acrostic:minimize_transposition()
  local chord_octaves={
    {0,0,0,0},
    {0,0,0,0},
  }
  for ppage=1,2 do
    local roman_numerals={}
    for chord=1,4 do
      table.insert(roman_numerals,self.available_chords[params:get("chord"..ppage..chord)])
    end
    local note_name_matrix=phrase_generate_low_high(params:get("root_note"),roman_numerals,{2,2,3,3,3,4})
    self.matrix_octave[ppage]={}
    self.matrix_base[ppage]={}
    for note=1,6 do
      self.matrix_octave[ppage][note]={}
      self.matrix_base[ppage][note]={}
      for chord=1,4 do
        self.matrix_octave[ppage][note][chord]=12*chord_octaves[ppage][chord]
        self.matrix_base[ppage][note][chord]=MusicUtil.note_name_to_num(note_name_matrix[note][chord])
      end
    end
  end
  self:update_final()
end

-- minimize_transposition transposes each chord for minimal distance
function Acrostic:minimize_transposition_old(changes)
  self:msg("regen notes")
  local chords={}
  local chord_notes={}
  for chord=1,4 do
    local notes=MusicUtil.generate_chord_roman(params:get("root_note"),params:get("scale"),self.available_chords[params:get("chord"..self.page..chord)])
    chord_notes[chord]=table.clone(notes)
    table.rotatex(notes,math.random(0,2))
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

  self.matrix_octave[self.page]={}
  self.matrix_base[self.page]={}
  for note=1,6 do
    self.matrix_octave[self.page][note]={}
    self.matrix_base[self.page][note]={}
    for chord=1,4 do
      self.matrix_octave[self.page][note][chord]=0
      self.matrix_base[self.page][note][chord]=chord_notes[chord][1]%12+36
    end
  end
  local chords2={}
  for chord=1,4 do
    local chords2=table.clone(chords[chord])
    table.rotatex(chords2,math.random(0,2))
    --table.rotatex(chords[chord],math.random(0,3)) -- TODO: is this too randoM?
    for note,note_midi in ipairs(chords[chord]) do
      self.matrix_base[self.page][note][chord]=note_midi
    end
    local undone_note=#chords[chord]+1
    for i=undone_note,6 do
      self.matrix_base[self.page][i][chord]=chords2[i-undone_note+1]+12
    end
  end
  -- print("self.matrix_base[self.page]")
  -- table.print_matrix(self.matrix_base[self.page])
  self:update_final()
  print("update1")
  table.print_matrix(self.matrix_name[self.page])

  local averages={}
  for note=1,6 do
    for i=1,4 do
      self.matrix_base[self.page][note][i]=self.matrix_final[self.page][note][i]
      self.matrix_octave[self.page][note][i]=0
    end
    table.insert(averages,{table.average(self.matrix_final[self.page][note]),note})
  end
  table.sort(averages,function(a,b)
    return a[1]<b[1]
  end)
  local foo=table.clone(self.matrix_base[self.page])
  for i,v in ipairs(averages) do
    self.matrix_base[self.page][i]=foo[v[2]]
  end
  self.matrix_octave[self.page][1]={-12,-12,-12,-12}
  self.matrix_octave[self.page][3]={12,12,12,12}
  self.matrix_octave[self.page][4]={12,12,12,12}
  self.matrix_octave[self.page][5]={12,12,12,12}
  self.matrix_octave[self.page][6]={24,24,24,24}
  self:update_final()
end

function Acrostic:update_beats(update_softcut)
  local total_beats=0
  for page=1,params:get("number_of_chords") do
    for chord=1,4 do
      total_beats=total_beats+params:get("beats"..page..chord)
    end
  end
  self.loop_length=total_beats
  if update_softcut==nil or update_softcut then
    for i=1,6 do
      softcut.loop_end(i,self.o.minmax[i][2]+self.loop_length*clock.get_beat_sec())
    end
  end
end

function Acrostic:update_chords()
  for chord=1,4 do
    local chord_notes=MusicUtil.generate_chord_roman(params:get("root_note"),params:get("scale"),self.available_chords[params:get("chord"..self.page..chord)])
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
      self.matrix_base[self.page][i][chord]=note
    end
  end
  self:update_final()
end

function Acrostic:update_final()
  for page=1,2 do
    self.matrix_final[page]={}
    self.matrix_name[page]={}
    for note=1,6 do
      self.matrix_final[page][note]={}
      self.matrix_name[page][note]={}
      for chord=1,4 do
        self.matrix_final[page][note][chord]=self.matrix_base[page][note][chord]+self.matrix_octave[page][note][chord]
        self.matrix_name[page][note][chord]=MusicUtil.note_num_to_name(self.matrix_final[page][note][chord],true)
      end
    end
  end
end

-- change_octave changes the octave for all four columns
function Acrostic:change_octave(row,d)
  for chord=1,4 do
    self.matrix_octave[self.page][row][chord]=self.matrix_octave[self.page][row][chord]+d*12
  end

  self:update_final()
end

-- change_chord rotates the chords
function Acrostic:change_chord(chord,d)
  d=d*-1
  local t={}
  for note=1,6 do
    table.insert(t,self.matrix_final[self.page][note][chord])
  end

  table.rotatex(t,d)
  for note=1,6 do
    self.matrix_base[self.page][note][chord]=t[note]
    self.matrix_octave[self.page][note][chord]=0
  end

  self:update_final()
end

-- change_chord rotates the notes
function Acrostic:change_note(note,d)
  d=d*-1
  local t={}
  for chord=1,4 do
    table.insert(t,self.matrix_final[self.page][note][chord])
  end

  table.rotatex(t,d)
  for chord=1,4 do
    self.matrix_base[self.page][note][chord]=t[chord]
    self.matrix_octave[self.page][note][chord]=0
  end

  self:update_final()
end

function Acrostic:key(k,z)
  if z==0 then
    do return end
  end

  if params:get("sel_selection")==1 then
    if k==2 then
      if math.random()<0.5 then
        self:minimize_transposition()
      else
        self:minimize_transposition(true)
      end
    elseif k==3 then
      print("self:toggle_start",global_shift)
      self:toggle_start(global_shift)
    end
  end
  if params:get("sel_selection")==2 then
    if global_shift then
      if k==3 then
        local note=self.matrix_final[self.page][1][params:get("sel_chord")]
        local octave=(note-(note%12))/12
        for note=1,6 do
          self.matrix_octave[self.page][note][params:get("sel_chord")]=0
          self.matrix_base[self.page][note][params:get("sel_chord")]=(self.matrix_base[self.page][note][params:get("sel_chord")]%12)+octave*12
        end
      end
    else
      self:mod_octave_chord(self.page,params:get("sel_chord"),k*2-5)
    end
    self:update_final()
  end
  if params:get("sel_selection")==3 then
    if global_shift then
      if k==3 then
        self:copy_octave_to_all(self.page,params:get("sel_note"))
      end
    else
      self:mod_octave(self.page,params:get("sel_note"),k*2-5)
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
      self:initiate_recording()
    else
      self:queue_recording(params:get("sel_cut"))
    end
    self.debounce_chord_selection=0
  end
end

function Acrostic:mod_octave_chord(ppage,sel_chord,val)
  for note=1,6 do
    self.matrix_octave[ppage][note][sel_chord]=self.matrix_octave[ppage][note][sel_chord]+12*val
  end
end

function Acrostic:mod_octave(ppage,nnote,val)
  for chord=1,4 do
    self.matrix_octave[ppage][nnote][chord]=self.matrix_octave[ppage][nnote][chord]+12*val
  end
end

function Acrostic:initiate_recording()
  local queued={}
  for _,v in ipairs(self.rec_queue) do
    table.insert(queued,v.i)
  end
  local foo={}
  local oooooo_ordering={5,2,1,6,4,3}
  table.shuffle(oooooo_ordering)
  -- oooooo_ordering={3,2,1,5,4,6}
  for i=1,6 do
    if not self.recorded[i] and not table.contains(queued,i) then
      table.insert(foo,oooooo_ordering[i])
    end
  end
  --table.shuffle(foo) -- TODO: maybe allow shuffling as an option?
  for _,i in ipairs(foo) do
    self:queue_recording(i)
  end
end

function Acrostic:queue_recording(i)
  print("queue_recording",i)
  table.insert(self.rec_queue,{i=i,recording=false,primed=false})
end

function Acrostic:beats_left(i)
  return math.ceil(self.loop_length*(1-(self.o.pos[i]/(self.loop_length*clock.get_beat_sec()))))
end

function Acrostic:copy_octave_to_all(ppage,sel_note)
  print("copy_octave_to_all",sel_note)
  local note=self.matrix_final[ppage][sel_note][1]
  local octave=(note-(note%12))/12
  for chord=1,4 do
    self.matrix_octave[ppage][sel_note][chord]=0
    self.matrix_base[ppage][sel_note][chord]=(self.matrix_base[ppage][sel_note][chord]%12)+octave*12
  end
end

function Acrostic:enc(k,d)
  if global_shift then
    if k==1 then
    elseif k==2 and (params:get("sel_selection")==2 or params:get("sel_selection")==3) then
      self:change_note(params:get("sel_note"),d)
      self.debounce_chord_selection=20
    elseif k==3 and (params:get("sel_selection")==2 or params:get("sel_selection")==3) then
      self:change_chord(params:get("sel_chord"),d)
      self.debounce_chord_selection=20
    elseif k==2 and params:get("sel_selection")==1 then
      params:delta("sel_chord",d)
      self.debounce_chord_selection=20
      self.do_set_cut_to_1=true
    elseif k==3 and params:get("sel_selection")==1 then
      params:delta("beats"..self.page..params:get("sel_chord"),d)
      self.debounce_chord_selection=20
    elseif k==2 and params:get("sel_selection")==4 then
      params:delta("pre_level"..params:get("sel_cut"),d)
      self:msg("pre: "..params:get("pre_level"..params:get("sel_cut")))
    elseif k==3 and params:get("sel_selection")==4 then
      params:delta("rec_level"..params:get("sel_cut"),d)
      self:msg("rec: "..params:get("rec_level"..params:get("sel_cut")))
    end
    do return end
  end
  if k==1 then
    params:delta("sel_selection",math.sign(d))
  elseif k==2 then
    if params:get("sel_selection")==1 then
      params:delta("sel_chord",d)
      self.debounce_chord_selection=20
      self.do_set_cut_to_1=true
    elseif params:get("sel_selection")==4 then
      params:delta("sel_cut",d)
    else
      params:delta("sel_note",d)
      params:set("sel_cut",params:get("sel_note"))
      params:set("sel_selection",3)
      self.debounce_chord_selection=20
    end
  elseif k==3 then
    if params:get("sel_selection")==1 then
      params:delta("chord"..self.page..params:get("sel_chord"),d)
      self.debounce_chord_selection=20
      self.do_set_cut_to_1=true
    elseif params:get("sel_selection")==4 then
      params:delta(params:get("sel_cut").."vol adj",d)
      print("lvl: "..params:get(params:get("sel_cut").."vol adj"))
      self:msg("lvl: "..params:get(params:get("sel_cut").."vol adj"))
    else
      params:delta("sel_chord",d)
      params:set("sel_selection",2)
      self.debounce_chord_selection=20
      self.do_set_cut_to_1=true
    end
  end
end

function Acrostic:update()
  if self.do_update_chords~=nil and self.do_update_chords then
    self.do_update_chords=nil
    self:update_chords()
  end
  if self.do_update_beats~=nil and self.do_update_beats then
    self.do_update_beats=nil
    self:update_beats()
  end
  if self.debounce_chord_selection>0 then
    self.debounce_chord_selection=self.debounce_chord_selection-1
  end
  local ct=clock.get_beat_sec()*clock.get_beats()
  for i=1,6 do
    self.pan[i]=params:get(i.."pan lfo amp")*calculate_lfo(ct,params:get(i.."pan lfo period"),params:get(i.."pan lfo offset"))
    self.pan[i]=util.clamp(params:get(i.."pan adj")+self.pan[i],-1,1)
    softcut.pan(i,self.pan[i])

    self.vol[i]=util.linlin(-1,1,0,1,params:get(i.."vol lfo amp")*calculate_lfo(ct,params:get(i.."vol lfo period"),params:get(i.."vol lfo offset")))
    self.vol[i]=util.clamp(params:get(i.."vol adj")+self.vol[i],0.01,0.99)
    softcut.level(i,self.vol[i])
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
    local chord_text=""
    if global_shift and params:get("sel_selection")==1 then
      chord_text=params:get("beats"..self.page..i)
    else
      chord_text=self.available_chords[params:get("chord"..self.page..i)]
    end
    screen.move(8+(i-1)*19,7)
    screen.text_center(chord_text)
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
      table.insert(notes,self.matrix_name[self.page][j][i])
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

  if self.message_level>0 and self.message~="" then
    self.message_level=self.message_level-2
    screen.move(100,8)
    screen.level(self.message_level)
    screen.text_center(self.message)
  else
    local foo=""
    for i,q in ipairs(self.rec_queue) do
      if i==1 then
        if q.recording then
          foo="r"..q.i.." "
          if #self.rec_queue>1 then
            foo=foo.."q"
          end
        else
          foo="q"..q.i.." "
        end
      else
        foo=foo..q.i.." "
      end
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
end

return Acrostic
