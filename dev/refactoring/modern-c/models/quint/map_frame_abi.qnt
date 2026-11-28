module map_frame_abi {
 // Three invocations, one captured chain, two real normal-return shapes. Source simulation open.
 type State={cb:int,rc:int,fs:int,link:int,captured:bool,root:bool,pin:bool,running:bool,
 epoch:int,loaded:int,shots:int,frameAbi:int,runtimeAbi:int,abi:int,emitAbi:int,objAbi:int,
 emitted:bool,native:bool,tool:int,objTool:int}
 pure val initial:State={cb:7,rc:9,fs:5,link:0,captured:false,root:false,pin:false,running:false,
 epoch:0,loaded:0,shots:0,frameAbi:1,runtimeAbi:1,abi:1,emitAbi:1,objAbi:1,
 emitted:true,native:true,tool:1,objTool:1}
 var s:State
 action init=s'=initial
 val safe=all{s.cb==7,s.rc==9,s.fs==5,s.link==0,s.shots>=0,s.shots<=3,
 s.captured implies (s.root and s.pin and s.frameAbi==s.runtimeAbi),
 s.running implies (s.captured and s.loaded==s.epoch),
 s.emitted implies s.emitAbi==s.abi,
 s.native implies (s.emitted and s.objAbi==s.abi and s.objTool==s.tool)}
 action capture=all{not(s.captured),not(s.running),s'={...s,captured:true,root:true,pin:true,frameAbi:s.runtimeAbi,shots:0}}
 action collect=all{s.captured,s.root,not(s.running),s'={...s,epoch:s.epoch+1}}
 action reload=all{not(s.running),s'={...s,loaded:s.epoch}}
 action resume=all{s.captured,s.root,s.pin,not(s.running),s.loaded==s.epoch,s.shots<3,s'={...s,running:true,shots:s.shots+1}}
 action returnShot=all{s.running,s'={...s,running:false}}
 action abiEdit=all{true,s'={...s,abi:s.abi+1,emitted:false,native:false}}
 action emit=all{true,s'={...s,emitAbi:s.abi,emitted:true,native:false}}
 action compile=all{s.emitted,s'={...s,objAbi:s.emitAbi,objTool:s.tool,native:true}}
 action toolEdit=all{true,s'={...s,tool:s.tool+1,native:false}}
 action bind=all{s.native,not(s.captured),not(s.running),s'={...s,runtimeAbi:s.abi}}
 action releaseCaptured=all{s.captured,not(s.running),s'={...s,captured:false,root:false,pin:false}}
 action step=any{capture,collect,reload,resume,returnShot,abiEdit,emit,compile,toolEdit,bind,releaseCaptured,all{s'=s}}
 action shot=resume.then(returnShot)
 run threeShotsTest=init.then(capture).then(shot).then(collect).then(reload).then(shot).then(shot).then(all{assert(safe and s.shots==3 and s.captured),s'=s})
 run abiCandidateDoesNotOverwriteLiveTest=init.then(capture).then(shot).then(abiEdit).then(emit).then(compile).then(collect).then(reload).then(shot).then(all{assert(safe and s.abi==2 and s.runtimeAbi==1 and s.frameAbi==1),s'=s})
 run rebindAfterQuiescenceTest=init.then(capture).then(shot).then(abiEdit).then(emit).then(compile).then(releaseCaptured).then(bind).then(capture).then(all{assert(safe and s.frameAbi==2 and s.runtimeAbi==2),s'=s})
 run toolOnlyKeepsEmissionTest=init.then(toolEdit).then(all{assert(safe and s.emitted and not(s.native) and s.abi==1),s'=s})
 run sameSizedFramesHaveDifferentRootsTest=init.then(all{assert(safe and s.cb!=s.rc and s.fs==5),s'=s})
 run oldDescriptorPinSurvivesRebuildTest=init.then(capture).then(abiEdit).then(emit).then(compile).then(all{assert(safe and s.pin and s.runtimeAbi==1),s'=s})
 run unionMaskControlTest=init.then(all{s'={...s,cb:15}}).then(all{assert(not(safe)),s'=s})
 run reuseCallbackMaskControlTest=init.then(all{s'={...s,rc:7}}).then(all{assert(not(safe)),s'=s})
 run rebindLiveFrameControlTest=init.then(capture).then(abiEdit).then(all{s'={...s,runtimeAbi:2}}).then(all{assert(not(safe)),s'=s})
 run resumeWithoutReloadControlTest=init.then(capture).then(collect).then(all{s'={...s,running:true}}).then(all{assert(not(safe)),s'=s})
 run dropLiveCodePinControlTest=init.then(capture).then(all{s'={...s,pin:false}}).then(all{assert(not(safe)),s'=s})
 run staleObjectReuseControlTest=init.then(abiEdit).then(all{s'={...s,native:true}}).then(all{assert(not(safe)),s'=s})
}
