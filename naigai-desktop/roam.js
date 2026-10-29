// Window locomotion only: preserves the original directional sprite artwork.
let roamEnabled=true,roamDirection=-1,roamUntil=0,roamStart=0;
let restUntil=performance.now()+4000,roamLast=null,nativeHidden=false;
function setRoaming(enabled){roamEnabled=enabled;roamUntil=0;restUntil=performance.now()+1000;if(!paused)setState(0)}
function reverseRoaming(direction){roamDirection=direction;if(roamUntil)setState(direction>0?1:2)}
function roamFrame(now){
 const dt=roamLast===null?0:Math.min(.05,(now-roamLast)/1000);roamLast=now;
 if(!(typeof sleeping!=='undefined'&&sleeping)&&!(typeof pottyActive!=='undefined'&&pottyActive)&&!(typeof folderActive!=='undefined'&&folderActive)&&roamEnabled&&!paused&&!nativeHidden&&!drag&&now>=restUntil){
  if(!roamUntil){if(locked&&row!==1&&row!==2){restUntil=now+1000}else{roamStart=now;roamUntil=now+6000+Math.random()*4000;setState(roamDirection>0?1:2)}}
  if(roamUntil){
   const ease=Math.min(1,(now-roamStart)/800,(roamUntil-now)/800);
   const velocity=18*(.5-.5*Math.cos(Math.PI*Math.max(0,ease)));
   bridge.postMessage({action:'step',dx:velocity*dt*roamDirection});
   if(now>=roamUntil){roamUntil=0;restUntil=now+5000+Math.random()*7000;roamDirection*=-1;setState(0)}
  }
 }
 requestAnimationFrame(roamFrame);
}
requestAnimationFrame(roamFrame);
