-- acrostic
--

--engine.name="Acrostic"
engine.name="MxSynths"

local acrostic_=include("acrostic/lib/acrostic")

function init()
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new()

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

