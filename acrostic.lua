-- acrostic
--


samples_test={}

function init()
  softcut.reset()
  softcut.buffer_read_mono("/home/we/dust/audio/tehn/mancini1.wav",0,0,-1,1,1,0,1)
  softcut.render_buffer(1,0,2,55)
  softcut.event_render(function(ch,start,sec_per_sample,samples)
    samples_test=samples
    tab.print(samples)
  end)
	clock.run(function()
		while true do
			clock.sleep(1/10)
			redraw()
		end
	end)
end


drawer=function()
  -- block for the top
  -- screen.level(15)
  -- screen.rect(0,0,70,9)
  -- screen.fill()
  screen.level(0)
  local chords={"C#4","Bb7","vi","V"}
  for i,chord in ipairs(chords) do
    if i==1 then
      screen.level(0)
    else
      screen.level(3)
    end
    screen.level(15)
    screen.move(8+(i-1)*19,7)
    screen.text_center(chord)
  end
  screen.level(15)
  local highlight_row=false
  local highlight_col=true
  if highlight_row then
    screen.level(15)
    screen.rect(1,10+9*0,71,9)
    screen.fill()
  end
  for i=1,4 do
    local xx=8+(i-1)*19
    local yy=8
    local notes={"C4","E3","Gb4","E4","C6","E2"}
    if i==3 and highlight_col then 
      screen.level(15)
      screen.rect(xx-8,yy+2,16,64)
      screen.fill()
    else
      screen.level(15)
    end
    for j,note in ipairs(notes) do
      if highlight_row and j==1 then 
        screen.level(0)
      elseif highlight_col and i==3 then 
        if j==1 then 
          screen.level(0)
        else
          screen.level(3)
        end
      else
        screen.level(15)
      end
      screen.move(xx,yy+9*j)
      screen.text_center(note)
    end
  end
  for j=1,6 do 
    local y=5+9*j
    -- screen.move(8+(4-1)*19+8,y)
    -- -- screen.line(126,y)
    -- for i,sample in ipairs(samples_test) do
    --   -- screen.pixel(7+(4-1)*19+8+(i-1),y+util.linlin(-1,1,-3,3,sample))
    --   local xx=8+(4-1)*19+8+(i-1)
    --   local yy=y+util.linlin(-1,1,-5,5,math.abs(sample))
    --   screen.line(xx,yy)
    --   screen.stroke()
    --   screen.move(xx,yy)
    -- end
    local levels={12,5,2,1}
    for sign=-1,1,2 do
      for kk=4,1,-1 do
        screen.level(levels[kk])
        screen.move(11+(4-1)*19+8,y)
        for i,sample in ipairs(samples_test) do
          local xx=11+(4-1)*19+8+(i-1)
          local yy=y+util.linlin(-1,1,-1*kk,kk,sign*math.abs(sample))
          screen.line(xx,yy)
          screen.stroke()
          screen.move(xx,yy)
        end
      end
    end
  end
end

function redraw()
	screen.clear()
	if drawer~=nil then 
		drawer()
	end
	screen.update()
end
