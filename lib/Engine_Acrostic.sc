Engine_Acrostic : CroneEngine {

	var synthAutotune;
	var paramsAutotune;
	var synthMonosaw;
	var paramsMonosaw;
	var osfun;
	var bufs;
	var amps;
	var syns;
	var loading=false;

	alloc { 

		bufs=Dictionary.new();
		syns=Dictionary.new();
		amps=Dictionary.new();

		SynthDef("sample",{
			arg amp=0,buf,gate=1;
			var snd=PlayBuf.ar(2,buf,rate:BufRateScale.ir(buf),loop:1);
			snd=snd*EnvGen.ar(Env.adsr(1,1,1,1),gate,doneAction:2);
			Out.ar(0,snd*Lag.kr(amp));
		}).add;

		this.addCommand("sync","",{ arg msg;
	        syns.keysValuesDo({ arg fname, val;
				("[sample] syncing"+fname).postln;
	        	val.set(\gate,0);
				syns.put(fname,Synth.new("sample",[\amp,amps.at(fname),\buf,bufs.at(fname)]));
				NodeWatcher.register(syns.at(fname));
	        });
		});

		this.addCommand("load_sample", "s", { arg msg;
			var fname=msg[1];
			Buffer.read(Server.default,fname.asString,action:{ arg buf;
				("[sample] loaded"+fname).postln;
				bufs.put(fname,buf);
				syns.put(fname,Synth.new("sample",[\amp,0,\buf,bufs.at(fname)]));
				NodeWatcher.register(syns.at(fname));
			});
		});

		this.addCommand("amp_sample", "sf", { arg msg;
			var fname=msg[1];
			var amp=msg[2];
			amps.put(fname,amp);
			syns.at(fname).set(\amp,amp);
		});

		SynthDef("autotune", {
			arg hz=220,amp=0.0,mix=0.0,amplitudeMin=1;
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
			arg hz=110,amp=0.0,detuning=0.025,lpfmin=200,lpfadj=4000,lpflfo=1,delay=1,feedback=0;
			var snd,fx,y,z, bass, basshz,lpffreq,lpffreq2,local,lpfosc1,lpfosc2;
			var note=hz.cpsmidi;
			
			amp=Lag.kr(amp);
			delay=Lag.kr(delay);
			feedback=Lag.kr(feedback);
			hz=Lag.kr(hz,0.05);
			detuning=Lag.kr(detuning);
			lpfmin=Lag.kr(lpfmin);
			lpfadj=Lag.kr(lpfadj);
			lpflfo=Lag.kr(lpflfo);
			snd={
				var osc1,osc2,env,snd;
				snd=Saw.ar((note+(Rand(-1.0,1.0)*detuning)).midicps);
				snd=DelayC.ar(snd, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15 );
				Pan2.ar(snd,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/4
			};
			snd=snd+{
				var osc1,osc2,env,snd;
				snd=Saw.ar((note+(Rand(-1.0,1.0)*detuning)).midicps/2);
				snd=DelayC.ar(snd, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15 );
				Pan2.ar(snd,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/12
			};
			snd=snd+{
				var osc1,osc2,env,snd;
				snd=Saw.ar((note+(Rand(-1.0,1.0)*detuning)).midicps*2);
				snd=DelayC.ar(snd, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15 );
				Pan2.ar(snd,VarLag.kr(LFNoise0.kr(1/3),3,warp:\sine))/24
			};
			
			lpfmin=Clip.kr(lpfmin,20,18000);
			lpfadj=Clip.kr(lpfmin+lpfadj,20,20000);

			lpfosc1=SinOsc.kr(lpflfo*VarLag.kr(LFNoise0.kr(lpflfo),1/lpflfo).range(0.8,1.2));
			lpfosc2=SinOsc.kr(lpflfo*VarLag.kr(LFNoise0.kr(lpflfo),1/lpflfo).range(0.8,1.2));
			lpffreq=LinExp.kr(lpfosc1,-1,1,lpfmin,lpfadj);
			lpffreq2=LinExp.kr(lpfosc2,-1,1,lpfmin,lpfadj);
			SendTrig.kr(Impulse.kr(10.0),1,lpffreq);
			SendTrig.kr(Impulse.kr(10.0),2,SelectX.kr(feedback,[lpffreq,lpffreq2]));
			
			snd=MoogLadder.ar(snd.tanh,lpffreq,SinOsc.kr(0.125).range(0.0,0.1));
			
			local = LocalIn.ar(2);
			local = HPF.ar(local,100);
			local = LPF.ar(local,8000);
			local = OnePole.ar(local, 0.4);
			local = OnePole.ar(local, -0.08);
			local = Rotate2.ar(local[0], local[1], 0.2);
			local = DelayN.ar(local, 0.25, 0.25*delay)+DelayN.ar(local, 0.5, 0.5*delay,0.5)+DelayN.ar(local, 0.75, 0.75*delay,0.25);
			local = LeakDC.ar(local);
			snd = ((local + snd) * 1.25).softclip;
			LocalOut.ar(snd*feedback);
			
			snd=HPF.ar(snd,20);
			//snd = snd + (NHHall.ar(snd, 8, modDepth: 1) * -15.dbamp);
			snd = DelayC.ar(snd, 0.2, SinOsc.ar(0.3, [0, pi]).linlin(-1,1, 0, 0.001));
			snd = snd * EnvGen.ar(Env.new([0,1],[1]));
			Out.ar(0,snd*amp);
		}).add;

		osfun = OSCFunc(
		{ 
			arg msg, time; 
			NetAddr("127.0.0.1", 10111).sendMsg("lpf",msg[2],msg[3]);   
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
			\delay,1,
			\feedback,0,
		]);
		paramsMonosaw.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				synthMonosaw.set(key,msg[1]);
			});
		});

	}

	free {
        bufs.keysValuesDo({ arg buf, val;
            val.free;
        });
        syns.keysValuesDo({ arg buf, val;
            val.free;
        });
   		synthAutotune.free;
		synthMonosaw.free;
		osfun.free;
	}

}