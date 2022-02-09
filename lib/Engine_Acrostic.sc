Engine_Acrostic : CroneEngine {

	var synthAutotune;
	var paramsAutotune;
	var synthMonosaw;
	var paramsMonosaw;
	var osfun;

	var encoder,decoder;
	var synthSphere;

	alloc { 

		synthSphere=Array.newClear(6);
		decoder = FoaDecoderMatrix.newStereo((131/2).degrad, 0.5);
		encoder = FoaEncoderMatrix.newOmni;

		SynthDef("crossfadingLooper2", {
			arg out=0, bufnum=0, rate=1, start=0, duration=1, amp=0.5, kill_trig=0;
			var snd,sndA,sndB,triggerSwap;
			var azim, angle, proxim, foa;

			rate=BufRateScale.ir(rate);
			triggerSwap=Trig.kr(Impulse.kr(1/duration/2),duration);

			sndA=PlayBuf.ar(1,bufnum,rate,triggerSwap,start,loop:0);
			sndB=PlayBuf.ar(1,bufnum,rate,(1-triggerSwap),start,loop:0);
			sndB=sndB*EnvGen.ar(Env.new([0,0,1,1],[duration,0.01,inf]));
			snd=sndA+sndB;

			snd = snd*amp;

			// for the 'push' transform later
			// see FoaPush help for details
			// angle ---> top           = push to plane wave (0)
			//            bottom        = omni-directional (pi/2)
			angle = pi/2;

			// Encode into our foa signal
			foa = FoaEncode.ar(snd, encoder);

			// push transform using angle
			foa = FoaTransform.ar(foa, 'pushX', angle);

			foa = FoaTransform.ar(foa, 'rtt',
				SinOsc.kr(Rand(1/60,1/30),Rand(0,pi)).range(Rand(-2*pi,0),Rand(0,2*pi)),
				SinOsc.kr(Rand(1/60,1/30),Rand(0,pi)).range(Rand(-2*pi,0),Rand(0,2*pi)),
				SinOsc.kr(Rand(1/60,1/30),Rand(0,pi)).range(Rand(-2*pi,0),Rand(0,2*pi)),
			);

			// decode our signal
			snd = FoaDecode.ar(foa, decoder);

			// start signal
			snd = snd*EnvGen.ar(Env.new([0,1,1],[1,inf]),1);
			// kill signal
			snd = snd*EnvGen.ar(Env.new([1,0],[1]),kill_trig,doneAction:2);

			Out.ar(out,snd);
		}).add;

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

		this.addCommand("load_tracks","ff",{ arg msg;
			synthSphere.do({ arg v,i;
				if (v.notNil,{
					v.set(\kill_trig,1);
				});
			});
			(1..6).do({arg i;
				Buffer.read(Server.default,"/home/we/dust/data/acrostic/acrostic-01.pset_"++i++".wav",action:{ arg buf;
					synthSphere.put(i-1,Synth("crossfadingLooper2",[\bufnum,buf,\rate,1,\duration,msg[1],\fadetime,msg[2],\amp,1.0]));
				});
			})
		});

		this.addCommand("unload_tracks","",{ arg msg;
			synthSphere.do({ arg v,i;
				if (v.notNil,{
					v.set(\kill_trig,1);
				});
			});
		});

	}

	free {
		synthAutotune.free;
		synthMonosaw.free;
		osfun.free;
		encoder.free;
		decoder.free;
		synthSphere.do({ arg v,i;
			if (v.notNil,{
				v.set(\kill_trig,1);
			});
		});
	}

}