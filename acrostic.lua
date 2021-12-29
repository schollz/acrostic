-- acrostic
--
local acrostic_=require("acrostic/lib/acrostic")

function init()
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
end

function key(k,z)

end

function enc(k,d)
  acrostic:enc(k,d)
end

function redraw()
  screen.clear()
  acrostic:draw()
  screen.update()
end
