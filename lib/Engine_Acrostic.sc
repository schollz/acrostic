Engine_Acrostic : CroneEngine {

	var synthAutotune;
	var paramsAutotune;
	var synthMonosaw;
	var paramsMonosaw;
	var osfun;

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

		SynthDef("monosaw",{
			arg hz=220,amp=0.0,detuning=0.025,lpfmin=6000,lpfadj=1000,lpflfo=1;
			var snd,fx,y,z, bass, basshz,lpffreq;
			var note=hz.cpsmidi;

			amp=Lag.kr(amp);
			hz=Lag.kr(hz,0.05);
			detuning=Lag.kr(detuning);
			lpfmin=Lag.kr(lpfmin);
			lpfadj=Lag.kr(lpfadj);
			lpflfo=Lag.kr(lpflfo);
			snd=Pan2.ar(Pulse.ar((note-12).midicps,LinLin.kr(LFTri.kr(0.5),-1,1,0.2,0.8))/12*amp);
			snd=snd+Mix.ar({
				var osc1,osc2,env,snd;
				snd=SawDPW.ar((note+(Rand(-1.0,1.0)*detuning)).midicps*TChoose.kr(Impulse.kr(0),[1,1,1,2,0.5,0.5,0.25]));
				snd=LPF.ar(snd,LinExp.kr(SinOsc.kr(rrand(1/30,1/10),rrand(0,2*pi)),-1,1,20,12000));
				snd=DelayC.ar(snd, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15 );
				Pan2.ar(snd,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/24*amp
			}!24);

			lpfmin=Clip.kr(lpfmin,20,18000);
			lpfadj=Clip.kr(lpfmin+lpfadj,20,20000);
			lpffreq=LinExp.kr(SinOsc.kr(lpflfo),-1,1,lpfmin,lpfadj);
			snd=MoogLadder.ar(snd.tanh,lpffreq,SinOsc.kr(0.125).range(0.0,0.1));
			SendTrig.kr(Impulse.kr(10.0),0,lpffreq);
			snd=HPF.ar(snd,20);
			Out.ar(0,snd);
		}).add;

		osfun = OSCFunc(
		{ 
			arg msg, time; 
			NetAddr("127.0.0.1", 10111).sendMsg("lpf",time,msg[3]);   
		},'/tr', context.server.addr);


		Server.default.sync;	
		// synthAutotune=Synth.new("autotune");	
		// paramsAutotune = Dictionary.newFrom([
		// 	\hz, 220,
		// 	\amp, 0.5,
		// 	\mix, 0,
		// 	\amplitudeMin,1,
		// ]);
		// paramsAutotune.keysDo({ arg key;
		// 	this.addCommand(key, "f", { arg msg;
		// 		synthAutotune.set(key,msg[1]);
		// 	});
		// });

		synthMonosaw=Synth.new("monosaw");
		paramsMonosaw = Dictionary.newFrom([
			\hz, 220,
			\amp, 0.5,
			\detuning, 0.05,
			\lpfmin,6000,
			\lpfadj,1000,
			\lpflfo,1,
		]);
		paramsMonosaw.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				synthMonosaw.set(key,msg[1]);
			});
		});

	}

	free {
		synthAutotune.free;
		synthMonosaw.free;
		osfun.free;
	}

}