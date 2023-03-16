-- acrostic v0.1.0
--
-- sample and layer chords
-- one note at a time.
--
-- llllllll.co/t/acrostic
--
--

engine.name="Acrostic"

global_shift=false
global_page=0
startup_eyes={
  irisSize=14,
  blinkState=3,
  blinkState2=3,
  volume=10,
  brightness=10,
}

function find_files(folder)
  local lines=util.os_capture("find "..folder.."* -print -type f -name '*.flac' -o -name '*.wav' | grep 'wav\\|flac' > /tmp/files")
  return lines_from("/tmp/files")
end

function lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines={}
  for line in io.lines(file) do
    lines[#lines+1]=line
  end
  return lines
end

function init()
  params:set("reverb",1)
  params:set("compressor",1)
  params:set("clock_tempo",135)
  norns.enc.sens(1,10)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)

  local acrostic_=include("acrostic/lib/acrostic")
  local monosaw_=include("acrostic/lib/monosaw")
  local volpan_=include("acrostic/lib/volpan")
  local notecontrol_=include("acrostic/lib/notecontrol")
  acrostic=acrostic_:new()
  acrostic:init()
  volpan=volpan_:new()
  volpan:init({acrostic=acrostic})
  notecontrol=notecontrol_:new()
  notecontrol:init()
  monosaw=monosaw_:new()
  monosaw:init()

  for i,loop in ipairs(find_files("/home/we/dust/audio/performances/performance3/")) do
    print(loop)
    pathname,filename,ext=string.match(loop,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    params:add_number(string.format("%dloop",i),filename:sub(1,20),0,200,0)
    engine.load_sample(loop)
    params:set_action(string.format("%dloop",i),function(v)
      engine.amp_sample(loop,v/100)
    end)
  end

  -- params:set("chord11",3,true)
  -- params:set("chord12",6,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",5,true)
  -- params:set("chord21",1,true)
  -- params:set("chord22",3,true)
  -- params:set("chord23",6,true)
  -- params:set("chord24",5,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats11",3)
  -- params:set("beats12",5)

  -- dunnno
  -- params:set("chord11",4,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",6,true)
  -- params:set("chord21",4,true)
  -- params:set("chord22",1,true)
  -- params:set("chord23",5,true)
  -- params:set("chord24",3,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats11",3)
  -- params:set("beats12",3)
  -- params:set("beats13",3)
  -- params:set("beats14",7)
  -- params:set("beats21",4)
  -- params:set("beats22",4)
  -- params:set("beats23",7)
  -- params:set("beats24",1)

  --
  -- params:set("chord11",1,true)
  -- params:set("chord12",3,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",1,true)
  -- params:set("chord21",4,true)
  -- params:set("chord22",5,true)
  -- params:set("chord23",3,true)
  -- params:set("chord24",1,true)
  -- params:set("number_of_chords",2)

  -- dont think twice
  -- params:set("chord11",1,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",6,true)
  -- params:set("chord14",6,true)
  -- params:set("chord21",4,true)
  -- params:set("chord22",4,true)
  -- params:set("chord23",1,true)
  -- params:set("chord24",5,true)
  -- params:set("number_of_chords",2)

  -- mr tambourine
  -- params:set("chord11",4,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",4,true)
  -- params:set("chord21",1,true)
  -- params:set("chord22",4,true)
  -- params:set("chord23",5,true)
  -- params:set("chord24",5,true)
  -- params:set("number_of_chords",2)

  -- params:set("chord11",5,true)
  -- params:set("chord12",6,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",1,true)
  -- params:set("chord21",1+14,true)
  -- params:set("chord22",3+14,true)
  -- params:set("chord23",1,true)
  -- params:set("chord24",4+14,true)
  -- params:set("number_of_chords",2)

  -- -- slts
  -- params:set("chord11",1,true)
  -- params:set("chord12",3,true)
  -- params:set("chord13",6,true)
  -- params:set("chord14",4,true)
  -- acrostic:change_chord(3,-1)
  -- acrostic:change_chord(4,-1)
  -- acrostic:copy_octave_to_all(1,6)
  -- -- acrostic:copy_octave_to_all(1,5)
  -- acrostic:update_final()
  -- params:set("beats11",5)
  -- params:set("beats12",3)
  -- params:set("beats13",3)
  -- params:set("beats14",5)

  -- -- wall of kiev
  -- params:set("clock_tempo",125)
  -- params:set("chord11",1,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",5,true)
  -- params:set("chord21",6,true)
  -- params:set("chord22",4,true)
  -- params:set("chord23",6,true)
  -- params:set("chord24",5,true)
  -- params:set("beats14",6)
  -- params:set("beats24",6)
  -- params:set("number_of_chords",2)
  -- clock.run(function()
  --   clock.sleep(1)
  --   -- acrostic:mod_octave_chord(1,2,1)
  --   -- acrostic:mod_octave_chord(2,2,1)
  --   -- acrostic:mod_octave_chord(2,4,1)
  --   acrostic:change_chord(2,-1)
  --   -- acrostic:change_chord(3,-1)
  --   -- acrostic:change_chord(4,-2)
  --   -- acrostic:copy_octave_to_all(1,5)
  --   acrostic:copy_octave_to_all(1,6)
  --   acrostic:update_final()
  --   acrostic.page=2
  --   acrostic:change_chord(2,-1)
  --   acrostic:change_chord(4,-1)
  --   acrostic:copy_octave_to_all(2,6)
  --   acrostic:update_final()
  --   -- for ppage=1,2 do
  --   --   for nnote=1,1 do
  --   --     acrostic:mod_octave(ppage,nnote,-1)
  --   --   end
  --   -- end
  --   acrostic:update_final()
  --   acrostic:initiate_recording() -- TODO: remove
  -- end)

  -- vi V IV iiim7
  -- params:set("chord11",6,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",3+14,true)

  -- vi iii IV V
  -- params:set("chord11",6,true)
  -- params:set("chord12",3,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",5,true)
  -- params:set("beats11",4)
  -- params:set("beats12",4)
  -- params:set("beats13",4)
  -- params:set("beats14",4)

  -- -- vi IV I V
  -- params:set("chord11",6,true)
  -- params:set("chord12",4,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",5,true)
  -- params:set("beats11",4)
  -- params:set("beats12",4)
  -- params:set("beats13",4)
  -- params:set("beats14",4)

  -- params:set("chord11",6,true)
  -- params:set("chord12",6,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",6,true)
  -- params:set("chord21",6,true)
  -- params:set("chord22",6,true)
  -- params:set("chord23",5,true)
  -- params:set("chord24",6,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats13",5)
  -- params:set("beats14",3)
  -- params:set("beats23",5)
  -- params:set("beats24",3)

  params:set("chord11",3,true)
  params:set("chord12",6,true)
  params:set("chord13",4,true)
  params:set("chord14",1,true)
  params:set("chord21",3,true)
  params:set("chord22",6,true)
  params:set("chord23",4,true)
  params:set("chord24",1,true)
  params:set("number_of_chords",2)
  params:set("beats21",4)
  params:set("beats22",4)
  params:set("beats23",4)
  params:set("beats24",4)

  -- ?? basic
  -- params:set("chord11",4,true)
  -- params:set("chord12",5,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",1,true)
  -- params:set("chord21",6,true)
  -- params:set("chord22",6,true)
  -- params:set("chord23",3,true)
  -- params:set("chord24",3,true)
  -- params:set("number_of_chords",2)

  -- philipglass
  -- params:set("clock_tempo",110)
  -- params:set("chord11",6,true)
  -- params:set("chord12",4,true)
  -- params:set("chord13",3+7,true)
  -- params:set("chord14",5,true)
  -- params:set("chord21",6,true)
  -- params:set("chord22",4,true)
  -- params:set("chord23",3,true)
  -- params:set("chord24",5,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats11",6)
  -- params:set("beats13",8)
  -- params:set("beats14",2)
  -- params:set("beats21",6)
  -- params:set("beats23",6)

  -- brande
  -- params:set("clock_tempo",115)
  -- params:set("chord11",6,true)
  -- params:set("chord12",3,true)
  -- params:set("chord13",1,true)
  -- params:set("chord14",4,true)
  -- params:set("chord21",6,true)
  -- params:set("chord22",3,true)
  -- params:set("chord23",4,true)
  -- params:set("chord24",1,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats11",4)
  -- params:set("beats12",2)
  -- params:set("beats13",2)
  -- params:set("beats14",6)
  -- params:set("beats21",4)
  -- params:set("beats22",3)
  -- params:set("beats23",3)
  -- params:set("beats24",6)

  -- sp
  -- params:set("chord11",6,true)
  -- params:set("chord12",4,true)
  -- params:set("chord13",5,true)
  -- params:set("chord14",1,true)
  -- params:set("chord11",1,true)
  -- params:set("chord12",14+14+5,true)
  -- params:set("chord13",6,true)
  -- params:set("chord14",6,true)
  -- params:set("chord21",2,true)
  -- params:set("chord22",2,true)
  -- params:set("chord23",4,true)
  -- params:set("chord24",4,true)
  -- params:set("number_of_chords",2)
  -- params:set("beats11",3)
  -- params:set("beats12",3)
  -- params:set("beats13",6)
  -- params:set("beats21",3)
  -- params:set("beats22",3)
  -- params:set("beats23",3)
  -- params:set("beats24",3)

  -- params:set("chord11",6,true)
  -- params:set("chord12",1,true)
  -- params:set("chord13",4,true)
  -- params:set("chord14",5,true)

  -- for i=1,6 do
  --   softcut.post_filter_dry(i,1)
  --   softcut.post_filter_hp(i,0)
  --   softcut.post_filter_lp(i,0)
  --   softcut.post_filter_fc(i,1*65.41)
  --   softcut.post_filter_rq(i,0.6)
  -- end

  params:set("monosaw_amp",0.0)
  acrostic.page=1
  acrostic:minimize_transposition(true)
  acrostic.page=2
  acrostic:minimize_transposition(true)
  acrostic.page=1

  -- testing

  acrostic.start_clock_after_phrase=0
  -- params:set("crow_1_pitch",2)

  acrostic:toggle_start(true)

  if #acrostic.midi_devices==1 and (not norns.crow.connected()) then
    params:set("monosaw_amp",0.5)
  end

  show_startup_screen_max=10
  show_startup_screen=0
  clock.run(function()
    while true do
      if show_startup_screen==show_startup_screen_max and global_page==0 then
        global_page=1
        acrostic:toggle_start()
        show_startup_screen=show_startup_screen+1
        acrostic:msg("k1+k3 records")
      end
      if show_startup_screen<show_startup_screen_max then
        startup_eyes.blinkState=util.linlin(0,show_startup_screen_max^2,3,0.001,show_startup_screen^2)
        startup_eyes.blinkState2=util.linlin(0,show_startup_screen_max^2,2.9,0.001,show_startup_screen^2)
        startup_eyes.volume=util.linlin(0,show_startup_screen_max,10,100,show_startup_screen)
        show_startup_screen=show_startup_screen+1
      end
      clock.sleep(1/10)
      acrostic:update()
      redraw()
    end
  end)

end

function cleanup()
end

function reroute_audio(startup)
  -- use the PARAMS > SOFTCUT to change the levels going into softcut
  if startup then
    audio.level_monitor(0)
    params:set("cut_input_adc",-90)
    params:set("cut_input_eng",-6)
    params:set("cut_input_tape",-90)
  else
    audio.level_monitor(1)
    params:set("cut_input_adc",-6)
    params:set("cut_input_eng",-6)
    params:set("cut_input_tape",-6)
  end
end

function key(k,z)
  if k==1 then
    global_shift=z==1
    if z==1 and (params:get("sel_selection")==2 or params:get("sel_selection")==3) then
      acrostic:msg("e2/e3 rotates")
    end
    do return end
  end
  if global_page==1 or global_page==2 then
    acrostic:key(k,z)
  elseif global_page==3 then
    volpan:key(k,z)
  elseif global_page==3 then
    notecontrol:key(k,z)
  elseif global_page==5 then
    monosaw:key(k,d)
  end
end

function enc(k,d)
  if global_shift and k==1 then
    -- change global_page
    global_page=util.clamp(global_page+d,1,5)
    if global_page<3 then
      acrostic:set_page(global_page)
    end
    do return end
  end
  if global_page==1 or global_page==2 then
    acrostic:enc(k,d)
  elseif global_page==3 then
    volpan:enc(k,d)
  elseif global_page==4 then
    notecontrol:enc(k,d)
  elseif global_page==5 then
    monosaw:enc(k,d)
  end
end

function redraw()
  if global_page==4 then
    if math.random()<0.6 then
      screen.clear()
    end
  else
    screen.clear()
  end
  -- monosaw:eyes(14,4,0,100,10)
  -- screen.update()
  -- do return end
  if global_page==1 or global_page==2 then
    acrostic:draw()
  elseif global_page==3 then
    volpan:draw()
  elseif global_page==4 then
    notecontrol:draw()
  elseif global_page==5 then
    monosaw:draw()
  elseif global_page==0 then
    monosaw:eyes(startup_eyes.irisSize,startup_eyes.blinkState,startup_eyes.blinkState2,startup_eyes.volume,startup_eyes.brightness)
  end
  screen.update()
end

