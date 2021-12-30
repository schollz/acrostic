-- acrostic
--

engine.name="Acrostic"
local acrostic_=include("acrostic/lib/acrostic")

function init()
  reroute_audio(true)
  acrostic=acrostic_:new()
  acrostic:update()

  clock.run(function()
    while true do
      clock.sleep(1/10)
      acrostic:update()
      redraw()
    end
  end)
end

function cleanup()
  reroute_audio(false)
end

function reroute_audio(startup)
  -- use the PARAMS > SOFTCUT to change the levels going into softcut
  if startup then
    audio.level_monitor(0)
    params:set("cut_input_adc",-inf)
    params:set("cut_input_eng",0)
    params:set("cut_input_tape",-inf)
  else
    audio.level_monitor(1)
    params:set("cut_input_adc",0)
    params:set("cut_input_eng",0)
    params:set("cut_input_tape",0)
  end
  -- if startup then
  --   -- disconnect system input to softcut
  --   os.execute("jack_disconnect system:capture_1 crone:input_1")
  --   os.execute("jack_disconnect system:capture_2 crone:input_2")
  --   -- connect supercollider to system capture directly
  --   os.execute("jack_disconnect crone:output_5 SuperCollider:in_1")
  --   os.execute("jack_disconnect crone:output_6 SuperCollider:in_2")
  --   os.execute("jack_connect system:capture_1 SuperCollider:in_1")
  --   os.execute("jack_connect system:capture_2 SuperCollider:in_2")
  -- else
  --   -- reset
  --   os.execute("jack_disconnect system:capture_1 SuperCollider:in_1")
  --   os.execute("jack_disconnect system:capture_2 SuperCollider:in_2")
  --   os.execute("jack_connect crone:output_5 SuperCollider:in_1")
  --   os.execute("jack_connect crone:output_6 SuperCollider:in_2")
  --   os.execute("jack_connect system:capture_1 crone:input_1")
  --   os.execute("jack_connect system:capture_2 crone:input_2")
  -- end
end

function key(k,z)
  acrostic:key(k,z)
end

function enc(k,d)
  acrostic:enc(k,d)
end

function redraw()
  screen.clear()
  acrostic:draw()
  screen.update()
end

