# acrostic

sample and layer chords, one note at a time.

![img](https://user-images.githubusercontent.com/6550035/148664651-35ae313d-be73-445a-9c39-1e193d3bd3ba.png)

acrostic lets you stack monophonic sound sources into chords with subtle melodies. basically, it is a sequencer that sends out one note at a time from specified chords while simultaneously recording those notes into individual tracks that are randomly modulated (wrt amplitude/pan). I used this script to [record an entire album "generations"](https://infinitedigits.bandcamp.com/album/generations) - every song on that album is an example of this script. this script originated as an addition to the [norns *oooooo* script](https://llllllll.co/t/oooooo/35828/476?u=infinitedigits), which itself originated from an idea I had while recording [an entire album from a cheap monophonic synthesizer](https://infinitedigits.bandcamp.com/album/at-the-place). 

you can read more about the theory below, but the gist of acrostic is that it will play a series of chords one note at a time at different octaves. the sequenced notes are then fed back into acrostic and are sampled in quantized loops that will combine to form the semblance of bass, pad, and melody lines. you can add up to six tracks, with up to eight chords with any number of beats per chord. you can use any instrument you want - midi, CV, or the internal engine (the "phantom" - the voice when no other voices are present). like *oooooo* each of the six tracks have random lfos in their amplitude/pan so it sounds as if they are "swirling" around.

I recorded a tutorial that includes a demo, a quick start and a in-depth overview (_note:_ some of the terminology changed since recording this and also there is no tutorial on the grid yet): 

[![gif](https://videoapi-muybridge.vimeocdn.com/animated-thumbnails/image/ab58d241-c235-4e2e-a21f-1f65f5cbaa8d.gif?ClientID=vimeo-core-prod&Date=1645549699&Signature=d179c0384b14904c248fe797efe09eb67ceae1db)](https://vimeo.com/663443176)

here are a few more demo performances:

https://vimeo.com/663740623

https://vimeo.com/663740704

https://vimeo.com/663740652

I want to express a huge thanks to Takahiro for implementing the eyes in their [wonderful three-eyes norns script](https://github.com/monome-community/nc01-drone/blob/master/three-eyes.lua) and thanks to Ezra for helping me integrate some softcut code to record single loops. thanks to Dewb for implementing the roman numeral chord generation which was super useful for this script. also big thanks to Jonathan who was a big inspiration for the demo video (I literaly took a page out his book displaying video text on a physical notebook).



# Requirements

- norns
- external midi or cv synth (optional)
- grid/midigrid (optional)
- crow (optional, requires [v3](https://llllllll.co/t/crow-v3/46425))

# Documentation

## quick start

0. (optional) plug in midi device or attach crow pitch to synth, route synth to norns input
1. start script, wait for the ghost's eyes to open.
2. press K1+K3.

## theory

basically "acrostic" is a script that lets you sequence and record very simple [voice leading](https://en.wikipedia.org/wiki/Voice_leading). the idea behind "acrostic" is to take several chords and then rearrange the notes in the chords to create a semblance of melody. for example: first suppose you chose four chords: Am, F, C, G. acrostic will first determine the notes for *each chord in a separate column*:

```
Am  F   C   G  
---------------
A   F   C   G
C   A   E   B
E   C   G   D
```


then *acrostic* will rearrange the notes of each chord in each column according to a particular algorithm (several algorithms are available and they are randomly selected). for example, the above might be re-arranged into the following:

```
Am  F   C   G  
---------------
C   C   C   D
A   A   G   G
E   F   E   B
```

the nature of the re-arrangement can help to induce natural melodies. *acrostic* re-arranges in many ways - trying to keep similar notes grouped together or minimizing distances (as in example above), maximizing distances, random, etc. the next step is to simply play each *row*, one note at a time, and over-dub the notes atop each other so that they form chords. also by putting notes in different octaves you can spread the chord around and get "bass" and "lead" lines.


## pages

the main UI is grouped into 4 pages. use K1+E1 to change pages. here are the four pages in acrostic:

1. the matrix (control note values)
2. the planets (control amp/pan)
3. the bars (controls note gating)
4. the phantom (controls internal engine)

the matrix does the sequencing and sampling and lets you modulate both. the planets lets you modulate the lfos for the volume and pan of the samples. the bars lets you gate and add interstitial notes. the phantom is a voice that you can use if you have no other voice.

## page 1) the matrix

![matrix](https://user-images.githubusercontent.com/6550035/148664651-35ae313d-be73-445a-9c39-1e193d3bd3ba.png)

the matrix is what lets you specify note pitches and their duration. you can pick chords, re-arrange the notes in the chord, and re-arrange/change the notes in the individual phrases. this particular UI has four "contexts". use E1 to change "context" within this page. they are as follows:

1. chords
2. notes
3. phrase
4. sampling

the chords context lets you pick the chords and allocate the beats. the notes context lets you rotate and change octave of notes in a chord. the phrase context lets you rotate notes and change octave in a phrase. the sampling context is where you initiate recording and can do some leveling.

### chord context

![chord context](https://user-images.githubusercontent.com/6550035/148664646-3bd20a3d-628b-4dbe-9d4d-13c317323d69.png)

this context lets you modify the chords. you are in the "chord context" when the bar around the roman numerals is highlighted.

- E2 or K1+E2 select chord position
- E3 change chord
- K1+E3 change beats of chord
- K2 regenerate notes
- K3 start/stop
- K1+K3 stop all

### note/phrase context

![note context](https://user-images.githubusercontent.com/6550035/148664645-64678f15-96ff-402a-98e9-c8af371c81f4.png)

![phrase context](https://user-images.githubusercontent.com/6550035/148664643-2e3d9ef8-290f-4fd8-b93a-b8f651d824ef.png)

this context lets you mainpulate/rotate/change pitches. you are in the "note context" when the columns are highlighted and you are in the "phrase context" when a row is highlighted. both of these contexts have the same controls/share controls.

- E2 select notes in chord
- E3 select phrase
- K1+E2 rotate notes in chord
- K1+E3 rotate phrase
- K2/K3 lower/raise octave of currently selected
- K1+K3 reset octaves of currently selected

### sampling context

![sampling context](https://user-images.githubusercontent.com/6550035/148664642-74596b94-a29d-4efe-9038-68993d8addb1.png)

this context lets you queue tracks for recording. you are in the "sampling context" when the sample area is highlighted.

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

the planets are representations of the current volume/pan for each track. they are automatically given random LFOs, but there are adjustments you can make manually. adjust parameters in `PARAMS > loop X` or from the phantom UI:

- K3 switches between loops
- E1 adjusts volume
- E2 adjust volume lfo amplitude
- E3 adjusts volume lfo period
- K2+E1 adjusts pan
- K2+E2 adjusts pan lfo amplitude
- K2+E3 adjusts pan lfo period

## page 3) the bars

![bars](https://user-images.githubusercontent.com/6550035/148664640-f5a7cc94-3de7-4da7-b8d3-c9903ab4735b.png)

the bars lets you modify the gating of notes and add new notes. adjust parameters in `PARAMS > notes` or from the phantom UI:

- E2 adjusts interstitial note probability
- E3 adjusts gate probabilty


## page 4) the phantom

![thephantom](https://user-images.githubusercontent.com/6550035/148664652-bcafc62b-e460-45de-ad4f-97cd6398c3cc.png)

the phantom is a voice when there are no other voices. it is driven by an internal engine which is automatically used when no crow or midi device is detected (if midi/crow is detected, then the volume of the phantom is set to 0 by default). adjust parameters in `PARAMS > phantom` or from the phantom UI:

- E1 adjusts LPF lfo frequency
- E2 adjusts LPF minimum cutoff
- E3 adjusts LPF maximum cutoff
- K1+E2 adjusts volume (by default its 0!, turn it up)
- K1+E3 adjusts feedback

## crow

the crow output is used to send out sequences. pitch 1 is the current sequencer pitch (1v/oct, but that can be modified in the parameters). the pitch will be the matrix sequencer, but switches over to the grid if the grid sequencer is active. crow output 2 is an envelope, which is by default activated when a chord change occurs (or when each note plays if the grid is active). crow output 3 is a clock which can be used to sync other instruments. crow output 4 is an oscillator which can be used to as a sub-oscillator to mix in bass.

- crow output 1 is pitch
- crow output 2 is envelope
- crow output 3 is clock
- crow output 4 is oscillator (I like to use as a sub-oscillator / tuner)

## grid

the grid is meant as a performative sequencer. in the parameters you can set whether the sequence resets every chord or not (`PARAMS > midi/grid/crow > reset every chord`). using the grid will "takeover" the crow outputs. when the grid stops playing, the crow will output as normal. _tip:_ if you sequence a single note you and just change notes and use it as a simple keyboard. here is a tutorial:

https://vimeo.com/680660126

**rows 1-6** controls pitch. you can use two finger gestures to draw shapes. the note shapes are applied the note matrix. the rows 1-3 notes that are always the same that come from each chord, 4 columns per chord (I mis-spoke in the tutorial and said 3 columns per chord). the rows 4-6 are notes that change with every chord. pressing a note again will transpose it, alternating up/down.

**row 7** controls duration. pressing a step twice will cause that note to hold. pressing two steps will reset their duration to the default (1/16th note).

**row 8** controls gates. pressing two gates will invert all gates in between.


## tips and tricks and gotchas


### melodies

there are two ways to add random melodies:

1. turn up `PARAMS > notes > inter-note probability`.
2. goto `PARAMS > notes > melody generator` and set it to `yes`.

if melodies are too "fast" you can turn down the gate probability (`PARAMS > notes > note gate probability`) to make them hold out longer.

### playing "phrases"

you can change the octave of phrases, while they are playing, to get higher/lower notes in case you want something to go into a "lead" sound or "bass" sound. actually, moving around the note/phrase stage will hold the note to that position.


### "tempo" gotchas

acrostic does not handle tempo changes well. its best to set the tempo you want and then start acrostic. if you do change the tempo, make sure to change the beats of a chord (you can change it from and back to) which will trigger acrostic to re-assign the sample lengths.

### non-sequencing

its fun to unplug all devices (midi/crow) and turn down the phantom and record in sounds played by *you* directly. just follow along with the notes specified in the matrix and let your own human sequencing unfold the layers.

### regenerate often

you can re-generate the notes in the matrix by going to the first page, turning E1 all the way CCW (to select the chord context), and then pressing K2. this will provide a whole new bed of notes which is useful if you are soloing and want the notes to be different than what is already recorded.


## future

- fix [problems with softcut.rec_once](https://github.com/monome/norns/pull/1494), an addition to softcut better utilizes softcut to make fade-able loops (current acrostic uses clocks+recpre slew to accomplish the same thing).
- option to introduce [ambisonics with head transfer functions](https://github.com/schollz/acrostic/blob/ambisonics/lib/Engine_Acrostic.sc#L14-L60) for more "swirling" for each track.

<details><summary>dev only - installing with softcut.rec_once</summary>
!!! do not follow these instructions unless you know what you are doing !!!

I created a patch for softcut that simplifies the recording and creating cross-fading loops.

requires a special patch to softcut and to norns.

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

don't do this unless you know what you are doing.
</details>


# Install

install with

```
;install https://github.com/schollz/acrostic
```

make sure to do `SYSTEM > RESTART` after installing or updating.