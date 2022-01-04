# acrostic

sample and layer chords.

![img](https://user-images.githubusercontent.com/6550035/147991374-42d4b89b-4141-44c0-9974-806f3dd70392.png)

acrostic lets you stack monophonic sound sources into chords with subtle melodies. basically, it is a sequencer that sends out one note at a time from chords to use the loops to record the entire chord phrase. it's described in more detail [here](https://llllllll.co/t/latest-tracks-videos/25738/3016) and is the basis of [an entire album I recorded](https://infinitedigits.bandcamp.com/album/at-the-place). 

this script was added as an addition to the [norns *oooooo* script](https://llllllll.co/t/oooooo/35828/476?u=infinitedigits) but I've broken it out into its own script. the major benefits in this script are:

- up to 8 chords can be added
- each chord has six notes that can be rearranged / modified
- each chord can be set to 0-16 beats long
- everything is accessible through the UI


# Requirements

- norns
- external synth (midi or cv)

# Documentation

## installation

requires latest softcut and a unreleased norns build.

first rebuild norns:

```bash
cd ~; ~/norns/stop.sh; rm -rf ~/norns; \
git clone git@github.com:schollz/norns && \
cd ~/norns && git checkout sc-rec-once && \
git submodule update --init --recursive && \
cd ~/norns/crone/softcut && \
git checkout main && \
cd ~/norns/crone/softcut/softcut-lib && \
./waf configure && \
./waf && \
cd ~/norns && \
./waf configure --enable-ableton-link && \
./waf build
```

then install acrostic:

```bash
rm -rf ~/dust/code/acrostic && \
git clone https://github.com/schollz/acrostic ~/dust/code/acrostic && \
cd ~/dust/code/acrostic && git checkout beta
```

then restart norns:

```bash
sudo systemctl restart norns-jack.service; \
sudo systemctl restart norns-matron.service; \
sudo systemctl restart norns-crone.service
```

## quick start

1. plug in a midi device or cv pitch to crow 1.
2. start script, wait for the ghost's eyes to open.
3. press K1+K3.


## sequencer

- K1+E1 changes page
- K1 shifts
- E1 changes context

### chord context

![chord context](https://user-images.githubusercontent.com/6550035/147990903-c156b2e9-6314-4c3c-98dd-cfc29cf04e2b.png)


- E2 or K1+E2 select chord position
- E3 change chord
- K1+K3 change beats of chord
- K2 transpose chords
- K3 start/stop

### note/phrase context

![note context](https://user-images.githubusercontent.com/6550035/147990908-f778ed71-577b-43a6-8c74-bceaf99a041a.png)

![phrase context](https://user-images.githubusercontent.com/6550035/147990909-3e52c93c-8d8e-4cb4-adcb-7bd3f9c98163.png)


- E2 select notes in chord
- E3 select phrase
- K1+E2 rotate notes in chord
- K1+E3 rotate phrase
- K2/K3 lower/raise octave of currently selected
- K1+K3 reset octaves of currently selected

### sampling context

![sampling context](https://user-images.githubusercontent.com/6550035/147990910-8f22641d-c8c0-4282-a9ff-8ebb26699667.png)

- E2 select sample
- K3 queues recording
- K3 dequeues recording
- K1+K2 erase recording
- K1+K3 queue unrecorded samples
- E3 change level
- K1+E2 changes pre
- K1+E3 chagnes rec

when you queue a recording (K3) it will begin recording at the next loop. you can queue multiple samples, even while one is recorindg.

![queue recording](https://user-images.githubusercontent.com/6550035/147990912-d93653b0-c08a-4d23-ad69-b79303cb9507.png)


## Install

install with

```
;install https://github.com/schollz/acrostic
```