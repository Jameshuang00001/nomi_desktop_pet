// Window locomotion only: preserves the original directional sprite artwork.
let roamEnabled=true,roamDirection=-1,roamUntil=0,roamStart=0,roamVertical=1,roamSlope=.6;
let restUntil=performance.now()+4000,roamLast=null,nativeHidden=false;
function setRoaming(enabled){roamEnabled=enabled;roamUntil=0;restUntil=performance.now()+1000;if(!paused)setState(0)}
function reverseRoaming(direction){roamDirection=direction;if(roamUntil)setState(direction>0?1:2)}
function reverseVertical(direction){roamVertical=direction}
function roamFrame(now){
 const dt=roamLast===null?0:Math.min(.05,(now-roamLast)/1000);roamLast=now;
 if(!(typeof sleeping!=='undefined'&&sleeping)&&!(typeof pottyActive!=='undefined'&&pottyActive)&&!(typeof folderActive!=='undefined'&&folderActive)&&roamEnabled&&!paused&&!nativeHidden&&!drag&&now>=restUntil){
  if(!roamUntil){if(locked&&row!==1&&row!==2){restUntil=now+1000}else{roamVertical=Math.random()<.5?-1:1;roamSlope=.35+Math.random()*.55;roamStart=now;roamUntil=now+6000+Math.random()*4000;setState(roamDirection>0?1:2)}}
  if(roamUntil){
   const ease=Math.min(1,(now-roamStart)/800,(roamUntil-now)/800);
   const velocity=36*(.5-.5*Math.cos(Math.PI*Math.max(0,ease)));
   const distance=velocity*dt/Math.hypot(1,roamSlope);
   bridge.postMessage({action:'step',dx:distance*roamDirection,dy:distance*roamSlope*roamVertical});
   if(now>=roamUntil){roamUntil=0;restUntil=now+5000+Math.random()*7000;roamDirection*=-1;setState(0)}
  }
 }
 requestAnimationFrame(roamFrame);
}
requestAnimationFrame(roamFrame);
