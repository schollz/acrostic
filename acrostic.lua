-- acrostic
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

function init()
  norns.enc.sens(1,10)
  norns.enc.sens(2,6)
  norns.enc.sens(3,6)

  local acrostic_=include("acrostic/lib/acrostic")
  local monosaw_=include("acrostic/lib/monosaw")
  monosaw=monosaw_:new()
  monosaw:init()
  acrostic=acrostic_:new()
  acrostic:init()

  -- params:set("chord1",1)
  -- params:set("chord2",3)
  -- params:set("chord3",6)
  -- params:set("chord4",4)
  params:set("chord11",3,true)
  params:set("chord12",6,true)
  params:set("chord13",4,true)
  params:set("chord14",5,true)
  params:set("chord21",1,true)
  params:set("chord22",3,true)
  params:set("chord23",6,true)
  params:set("chord24",5,true)
  params:set("monosaw_amp",0.0)
  acrostic.page=1 
  acrostic:minimize_transposition(true)
  acrostic.page=2 
  acrostic:minimize_transposition(true)
  acrostic.page=1

  -- testing

  acrostic.start_clock_after_phrase=0
  params:set("crow_1_pitch",2)

  acrostic:toggle_start(true)

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
    monosaw:key(k,d)
  end
end

function enc(k,d)
  if global_shift and k==1 then
    -- change global_page
    global_page=util.clamp(global_page+d,1,3)
    if global_page<3 then 
      acrostic:set_page(global_page)
    end
    do return end
  end
  if global_page==1 or global_page==2 then
    acrostic:enc(k,d)
  elseif global_page==3 then
    monosaw:enc(k,d)
  end
end

function redraw()
  screen.clear()
  -- monosaw:eyes(14,4,0,100,10)
  -- screen.update()
  -- do return end
  if global_page==1 or global_page==2 then
    acrostic:draw()
  elseif global_page==3 then
    monosaw:draw()
  elseif global_page==0 then 
    monosaw:eyes(startup_eyes.irisSize,startup_eyes.blinkState,startup_eyes.blinkState2,startup_eyes.volume,startup_eyes.brightness)
  end
  screen.update()
end

