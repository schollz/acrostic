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
git clone https://github.com/schollz/norns && \
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

## pages

use K1+E1 to change pages.

there are four pages in acrostic:

1. the matrix
2. the planets
3. the bars
4. the phantom

the matrix does the sequencing and sampling and lets you modulate both. the planets lets you modulate the lfos for the volume and pan of the samples. the bars lets you gate and add interstitial notes. the phantom is a voice that you can use if you have no other voice.

## the matrix page

use E1 to change "context" within this page. in the matrix there are four contexts:

1. chords
2. notes
3. phrase
4. sampling

the chords lets you pick the chords and allocate the beats. the notes context lets you rotate and change octave of notes in a chord. the phrase context lets you rotate notes and change octave in a phrase. the sampling context is where you initiate recording and can do some leveling.

### chord context

![chord context](https://user-images.githubusercontent.com/6550035/148656290-cb6c766c-fa4a-4dc1-932b-4ae5ca171623.png


- E2 or K1+E2 select chord position
- E3 change chord
- K1+K3 change beats of chord
- K2 transpose chords
- K3 start/stop

### note/phrase context

![note context](https://user-images.githubusercontent.com/6550035/148656287-5b40f2bd-f05d-4bdf-acf9-a0919e54b741.png)

![phrase context](https://user-images.githubusercontent.com/6550035/148656296-456530cb-76a6-40eb-84a0-9635d7e651a8.png)

both of these contexts have the same controls/share controls.

- E2 select notes in chord
- E3 select phrase
- K1+E2 rotate notes in chord
- K1+E3 rotate phrase
- K2/K3 lower/raise octave of currently selected
- K1+K3 reset octaves of currently selected

### sampling context

![sampling context](https://user-images.githubusercontent.com/6550035/148656295-0fab491c-b5f2-4846-b233-b8b3467d5264.png)

- E2 select sample
- K3 queues recording
- K3 dequeues recording
- K1+K2 erase recording
- K1+K3 queue unrecorded samples
- E3 change level
- K1+E2 changes pre
- K1+E3 chagnes rec

when you queue a recording (K3) it will begin recording at the next loop. you can queue multiple samples, even while one is recorindg.

## the planets

![planets](https://user-images.githubusercontent.com/6550035/148656294-ec41728e-35c3-4c1e-ba26-189c3ada703f.png)

## the bars

![planets](https://user-images.githubusercontent.com/6550035/148656293-e2ebfc14-3269-4ab8-a7b4-e84f3615cd14.png)


## the phantom

![thephantom](https://user-images.githubusercontent.com/6550035/148656292-7609719b-50be-4d8e-9c9c-a3c4e9c6c90f.png)


## Install

install with

```
;install https://github.com/schollz/acrostic
```