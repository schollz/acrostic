Engine_Acrostic : CroneEngine {

	var synthAutotune;
	var paramsAutotune;

	alloc { 

		SynthDef("autotune", {
			arg hz=220,amp=0.5,mix=0.0,amplitudeMin=1;
			var in, snd, freq, hasFreq, amplitude;
			in = Mix.new(SoundIn.ar([0,1]));
			amplitude=Lag.kr(Amplitude.kr(in),0.5);
			# freq, hasFreq = Tartini.kr(in);
			freq=Lag.kr(freq,0.5).poll;
			snd=PitchShift.ar(in,pitchRatio:hz/freq);
			snd=SelectX.ar(mix,[in,snd]);
			snd=SelectX.ar(amplitude>amplitudeMin,[Silent.ar(1),snd],0);
			Out.ar(0,snd.dup);
		}).add;


  		Server.default.sync;	
		synthAutotune=Synth.new("autotune");	

		paramsAutotune = Dictionary.newFrom([
			\hz, 220,
			\amp, 0.5,
			\mix, 0,
			\amplitudeMin,1,
		]);
		paramsAutotune.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				synthAutotune.set(key,msg[1]);
			});
		});
	}

	free {
		synthAutotune.free;
	}

}