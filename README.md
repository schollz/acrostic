# acrostic

sample and layer chords.

![img](https://user-images.githubusercontent.com/6550035/148664651-35ae313d-be73-445a-9c39-1e193d3bd3ba.png)

acrostic lets you stack monophonic sound sources into chords with subtle melodies. basically, it is a sequencer that sends out one note at a time from chords to use the loops to record the entire chord phrase. it's described in more detail [here](https://llllllll.co/t/latest-tracks-videos/25738/3016) and is the basis of [an entire album I recorded](https://infinitedigits.bandcamp.com/album/at-the-place). 

this script was added as an addition to the [norns *oooooo* script](https://llllllll.co/t/oooooo/35828/476?u=infinitedigits) but I've broken it out into its own script. the major benefits in this script are:

- up to 8 chords can be added
- each chord has six notes that can be rearranged / modified
- each chord can be set to 0-16 beats long
- everything is accessible through the UI
- additional controls for gating/adding notes

I recorded a tutorial that includes a demo, a quick start and a in-depth overview: 

https://vimeo.com/663443176

here are a few more demo performances:

https://vimeo.com/663740623

https://vimeo.com/663740704

https://vimeo.com/663740652

I want to express a huge thanks to Takahiro for implementing the eyes in their [wonderful three-eyes norns script](https://github.com/monome-community/nc01-drone/blob/master/three-eyes.lua) and thanks to Ezra for helping me integrate some softcut code to record single loops. also big thanks to Jonathan who was a big inspiration for the demo video (I literaly took a page out his book displaying video text on a physical notebook).



# Requirements

- norns
- external midi or cv synth (optional)

# Documentation

## installation

requires latest softcut and a unreleased norns build.

first rebuild norns:

```bash
sudo systemctl stop norns-jack.service; sudo systemctl stop norns-matron.service; sudo systemctl stop norns-crone.service && \
cd ~; ~/norns/stop.sh; rm -rf ~/norns; \
git clone https://github.com/schollz/norns && \
cd ~/norns && git checkout id && \
git submodule update --init --recursive && \
cd ~/norns/crone/ && rm -rf softcut && \
git clone https://github.com/schollz/softcut-lib softcut && \
cd softcut && git checkout id && \
cd ~/norns/crone/softcut/softcut-lib && \
./waf configure && \
./waf && \
cd ~/norns && \
./waf configure --enable-ableton-link && \
./waf build && \
sudo systemctl restart norns-jack.service; sudo systemctl restart norns-matron.service; sudo systemctl restart norns-crone.service
```

then install acrostic:

```bash
rm -rf ~/dust/code/acrostic && \
git clone https://github.com/schollz/acrostic ~/dust/code/acrostic
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

## page 1) the matrix

![matrix](https://user-images.githubusercontent.com/6550035/148664651-35ae313d-be73-445a-9c39-1e193d3bd3ba.png)

use E1 to change "context" within this page. in the matrix there are four contexts:

1. chords
2. notes
3. phrase
4. sampling

the chords lets you pick the chords and allocate the beats. the notes context lets you rotate and change octave of notes in a chord. the phrase context lets you rotate notes and change octave in a phrase. the sampling context is where you initiate recording and can do some leveling.

### chord context

![chord context](https://user-images.githubusercontent.com/6550035/148664646-3bd20a3d-628b-4dbe-9d4d-13c317323d69.png)

you are in the "chord context" when the bar around the roman numerals is highlighted.

- E2 or K1+E2 select chord position
- E3 change chord
- K1+K3 change beats of chord
- K2 transpose chords
- K3 start/stop

### note/phrase context

![note context](https://user-images.githubusercontent.com/6550035/148664645-64678f15-96ff-402a-98e9-c8af371c81f4.png)

![phrase context](https://user-images.githubusercontent.com/6550035/148664643-2e3d9ef8-290f-4fd8-b93a-b8f651d824ef.png)

you are in the "note context" when the columns are highlighted and you are in the "phrase context" when a row is highlighted. both of these contexts have the same controls/share controls.

- E2 select notes in chord
- E3 select phrase
- K1+E2 rotate notes in chord
- K1+E3 rotate phrase
- K2/K3 lower/raise octave of currently selected
- K1+K3 reset octaves of currently selected

### sampling context

![sampling context](https://user-images.githubusercontent.com/6550035/148664642-74596b94-a29d-4efe-9038-68993d8addb1.png)

you are in the "sampling context" when the sample area is highlighted.

- E2 select sample
- K3 queues recording
- K3 dequeues recording
- K1+K2 erase recording
- K1+K3 queue unrecorded samples
- E3 change level
- K1+E2 changes pre
- K1+E3 chagnes rec

when you queue a recording (K3) it will begin recording at the next loop. you can queue multiple samples, even while one is recorindg.

## page 2) the planets

![planets](https://user-images.githubusercontent.com/6550035/148664641-5f8c079a-6645-4fa7-8031-1643d886a515.png)

- K3 switches between loops
- E1 adjusts volume
- E2 adjust volume lfo amplitude
- E3 adjusts volume lfo period
- K2+E1 adjusts pan
- K2+E2 adjusts pan lfo amplitude
- K2+E3 adjusts pan lfo period

## page 3) the bars

![bars](https://user-images.githubusercontent.com/6550035/148664640-f5a7cc94-3de7-4da7-b8d3-c9903ab4735b.png)

- E2 adjusts interstitial note probability
- E3 adjusts gate probabilty


## page 4) the phantom

![thephantom](https://user-images.githubusercontent.com/6550035/148664652-bcafc62b-e460-45de-ad4f-97cd6398c3cc.png)

- E1 adjusts LPF lfo frequency
- E2 adjusts LPF minimum cutoff
- E3 adjusts LPF maximum cutoff
- K1+E2 adjusts volume
- K1+E3 adjusts feedback

## crow

the crow outputs are used for expression with CV instruments:

- crow output 1 is pitch
- crow output 2 is the note gate 
- crow output 3 is clock
- crow output 4 is a chord change gate

# Install

install with

```
;install https://github.com/schollz/acrostic
```