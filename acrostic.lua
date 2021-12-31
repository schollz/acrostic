-- acrostic
--

engine.name="Acrostic"

local acrostic_=include("acrostic/lib/acrostic")

function init()
  params:add{type="number",id="loop_length",name="loop length",min=4,max=64,default=16}
  -- TODO: save the number of loops and load it

  reroute_audio(true)
  acrostic=acrostic_:new()
  acrostic:init({loop_length=params:get("loop_length")})
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

