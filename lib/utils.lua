local MusicUtil=include("acrostic/lib/musicutil2")

function round_time_to_nearest_beat(t)
  seconds_per_qn=60/clock.get_tempo()
  remainder=t%seconds_per_qn
  if remainder==0 then
    return t
  end
  return t+seconds_per_qn-remainder
end

function calculate_lfo(current_time,period,offset)
  if period==0 then
    return 0
  else
    return math.sin(2*math.pi*current_time/period+offset)
  end
end

function math.sign(x)
  if x<0 then
    return-1
  else
    return 1
  end
end

function phrase_generate_low_high(root_note,roman_numerals,octaves)
  local chord_notes={}
  for chord=1,#roman_numerals do
    local notes=MusicUtil.generate_chord_roman(root_note,"Major",roman_numerals[chord])
    chord_notes[chord]=MusicUtil.note_nums_to_names(notes)
  end

  local m1=phrase_repeat_lowest(chord_notes)
  local m2=phrase_repeat_highest(chord_notes)
  table.merge(m1,m2)

  for note=1,#m1 do 
    local octave=octaves[note]
    for chord=1,#m1[note] do 
      if chord==1 then 
        m1[note][chord]=m1[note][chord]..octave
      else
        m1[note][chord]=MusicUtil.note_name_closest(m1[note][chord-1],m1[note][chord])
      end
    end
  end
  
  return m1
end

function phrase_repeat_lowest(chord_notes)
  local best_m={}
  local best_total=100
  for i=1,100 do 
    local m=phrase_generate_random(chord_notes,3)
    local total=phrase_count_duplicates(m)
    if total<best_total then 
      best_total = total 
      best_m=table.clone(m)
    end
  end
  return best_m
end



function phrase_repeat_highest(chord_notes)
  local best_m={}
  local best_total=0
  for i=1,100 do 
    local m=phrase_generate_random(chord_notes,3)
    local total=phrase_count_duplicates(m)
    if total>best_total then 
      best_total = total 
      best_m=table.clone(m)
    end
  end
  return best_m
end


function phrase_count_duplicates(m)
  local total = 0
  for i=1,#m do 
    local dups={}
    for j=1,#m[i] do 
      local c=m[i][j]
      if dups[c]~=nil then 
        dups[c]=dups[c]+1
      else
        dups[c]=0
      end
    end
    for _, v in pairs(dups) do
      total = total + v
    end
  end
  return total
end

function phrase_generate_random(chord_notes,notes)
  local cn=table.clone(chord_notes)
  local m={}
  for note=1,notes do 
    if (note-1)%3==0 then 
      for chord=1,4 do 
        table.permute(cn[chord])
      end
    end
    m[note]={}
    for chord=1,4 do
      m[note][chord]=cn[chord][(note-1)%3+1]
    end
  end
  return m
end