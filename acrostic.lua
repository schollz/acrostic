-- acrostic
--

-- engine.name="Acrostic"
local acrostic_=include("acrostic/lib/acrostic")

function init()
  -- softcut.buffer_write_mono("/home/we/dust/audio/rec_once_4.wav",0,4)
  -- reroute_audio(true)
  audio.level_monitor(1)
  acrostic=acrostic_:new()
  -- softcut.reset()
  -- softcut.buffer_read_mono("/home/we/dust/audio/tehn/mancini1.wav",0,0,-1,1,1,0,1)
  -- softcut.render_buffer(1,0,2,55)
  -- softcut.event_render(function(ch,start,sec_per_sample,samples)
  --   samples_test=samples
  --   tab.print(samples)
  -- end)
  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
  -- softcut.rec(1,1)
  -- softcut.rec(1,1)
  -- softcut.rec(1,0)
end

function reroute_audio(startup)
  if startup then
    -- disconnect system input to softcut
    os.execute("jack_disconnect system:capture_1 crone:input_1")
    os.execute("jack_disconnect system:capture_2 crone:input_2")
    -- connect supercollider to system capture directly
    os.execute("jack_disconnect crone:output_5 SuperCollider:in_1")
    os.execute("jack_disconnect crone:output_6 SuperCollider:in_2")
    os.execute("jack_connect system:capture_1 SuperCollider:in_1")
    os.execute("jack_connect system:capture_2 SuperCollider:in_2")
  else
    -- reset
    os.execute("jack_disconnect system:capture_1 SuperCollider:in_1")
    os.execute("jack_disconnect system:capture_2 SuperCollider:in_2")
    os.execute("jack_connect crone:output_5 SuperCollider:in_1")
    os.execute("jack_connect crone:output_6 SuperCollider:in_2")
    os.execute("jack_connect system:capture_1 crone:input_1")
    os.execute("jack_connect system:capture_2 crone:input_2")
  end
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

function cleanup()
  audio.level_monitor(1)
  -- reroute_audio(false)
end
