local MusicUtil=require("musicutil")

function MusicUtil.note_name_closest(note_w_octave,note_wo_octave)
  local note1=MusicUtil.note_name_to_num(note_w_octave)
  local best_note2=0
  local best_diff=1000
  for octave=0,7 do 
    local note2=MusicUtil.note_name_to_num(note_wo_octave..octave)
    local diff=math.abs(note2-note1)
    if diff<best_diff then 
      best_diff=diff
      best_note2=note_wo_octave..octave
    end
  end
  return best_note2
end

function MusicUtil.note_name_to_num(name)
  for i=0,127 do
    if MusicUtil.note_num_to_name(i,true)==name then 
      do return i end 
    end
  end
end

return MusicUtil