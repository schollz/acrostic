-- acrostic
--

engine.name="Acrostic"

global_shift=false
page=1


function init()
  local acrostic_=include("acrostic/lib/acrostic")
  local monosaw_=include("acrostic/lib/monosaw")
  monosaw=monosaw_:new()
  monosaw:init()
  engine.amp(1)

  params:add{type="number",id="loop_length",name="loop length (requires restart)",min=4,max=64,default=16}
  -- write/read the loop length
  filename_ll=_path.data.."acrostic/loop_length"
  params:set_action("loop_length",function(x)
    local file=io.open(filename_ll,"w+")
    io.output(file)
    io.write(x)
    io.close(file)
  end)
  if util.file_exists(filename_ll) then
    -- TODO: save the number of loops and load it
    local f=io.open(filename_ll,"rb")
    local content=f:read("*all")
    f:close()
    if content~=nil then
      params:set("loop_length",tonumber(content))
    end
  end

  acrostic=acrostic_:new()
  acrostic:init({loop_length=params:get("loop_length")})
  acrostic:update()
  params:set("chord1",3)
  params:set("chord2",6)
  params:set("chord3",4)
  params:set("chord4",5)
  acrostic:minimize_transposition(true)
  acrostic:minimize_transposition(true)
  acrostic:minimize_transposition(true)
  acrostic:minimize_transposition(true)
  acrostic:minimize_transposition(true)



  clock.run(function()
    while true do
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
    do return end
  end
  if page==1 then
    acrostic:key(k,z)
  elseif page==2 then
    monosaw:key(k,d)
  end
end

function enc(k,d)
  if global_shift and k==1 then
    -- change page
    page=util.clamp(page+d,1,2)
    do return end
  end
  if page==1 then
    acrostic:enc(k,d)
  elseif page==2 then
    monosaw:enc(k,d)
  end
end

function redraw()
  screen.clear()
  if page==1 then
    acrostic:draw(k,d)
  elseif page==2 then
    monosaw:draw(k,d)
  end
  screen.update()
end

