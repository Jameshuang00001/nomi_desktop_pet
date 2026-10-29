// Use the approved clean frames in forward/reverse order; the dropping is a
// separate native window so it never moves with the cat after being deposited.
let pottyElapsed=0,pottyLast=null,pottyFrame=-1,pottyDropped=false;
const pottyImage=new Image(),pottyCanvas=document.createElement('canvas');
pottyCanvas.width=384;pottyCanvas.height=416;pottyCanvas.style.cssText='position:absolute;inset:0;width:192px;height:208px;display:none;pointer-events:none';pet.appendChild(pottyCanvas);
const pottyContext=pottyCanvas.getContext('2d');pottyImage.src='potty-sheet.png';
function startPotty(){
 if(pottyActive||sleeping||paused||nativeHidden||drag||locked||roamUntil||!pottyImage.complete||!pottyImage.naturalWidth)return false;
 cancelLook();clearTimeout(timer);clearTimeout(release);clearTimeout(clickTimer);pottyActive=true;locked=true;roamUntil=0;
 pottyElapsed=0;pottyLast=null;pottyFrame=-1;pottyDropped=false;pottyCanvas.style.display='block';pet.style.backgroundImage='none';return true;
}
function finishPotty(){if(!pottyActive)return;pottyActive=false;pottyCanvas.style.display='none';pet.style.backgroundImage=`url(${img})`;restUntil=performance.now()+4000;setState(0);bridge.postMessage({action:'pottyFinished'})}
function pottyTick(now){
 if(pottyActive&&!paused&&!nativeHidden){
  if(pottyLast!==null)pottyElapsed+=Math.min(100,now-pottyLast);pottyLast=now;
  if(pottyElapsed>=3100&&!pottyDropped){pottyDropped=true;bridge.postMessage({action:'dropping'})}
  const times=[650,1100,1800,3400,3900,4350,5000],frames=[0,1,2,3,2,1,0];
  const idx=times.findIndex(t=>pottyElapsed<t);
  if(idx<0){finishPotty()}else{const f=frames[idx];if(f!==pottyFrame){pottyFrame=f;pottyContext.clearRect(0,0,384,416);pottyContext.drawImage(pottyImage,f*384,0,384,512,0,408-[436,434,434,434][f],384,512)}}
 }else pottyLast=null;
 requestAnimationFrame(pottyTick);
}
requestAnimationFrame(pottyTick);
