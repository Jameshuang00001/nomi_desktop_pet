// The approved eight-frame sheet, aligned by translation only.
let sleepElapsed=0,sleepLast=null,sleepFrame=-1;
const sleepImage=new Image(),sleepCanvas=document.createElement('canvas');
sleepCanvas.width=384;sleepCanvas.height=416;
sleepCanvas.style.cssText='position:absolute;inset:0;width:192px;height:208px;display:none;pointer-events:none';
pet.appendChild(sleepCanvas);
const sleepContext=sleepCanvas.getContext('2d');
sleepImage.onload=()=>sleepFrame=-1;sleepImage.src='sleep-sheet.png';
function setSleeping(value){
 if(sleeping===value)return;
 if(value&&typeof finishPotty==='function')finishPotty();
 sleeping=value;cancelLook();clearTimeout(timer);clearTimeout(release);clearTimeout(clickTimer);
 roamUntil=0;restUntil=performance.now()+4000;sleepLast=null;sleepFrame=-1;
 sleepCanvas.style.display=value?'block':'none';
 pet.style.backgroundImage=value?'none':`url(${img})`;
 pet.dataset.sleeping=String(value);pet.setAttribute('aria-label',value?'糯米正在睡觉':'糯米');
 if(value){locked=true;sleepElapsed=0}else{setState(0)}
}
function sleepTick(now){
 if(sleeping&&!paused&&!nativeHidden){
  if(sleepLast!==null)sleepElapsed+=Math.min(100,now-sleepLast);
  const f=Math.floor(sleepElapsed%4800/600);
  if(f!==sleepFrame&&sleepImage.complete&&sleepImage.naturalWidth){
   sleepFrame=f;sleepContext.clearRect(0,0,384,416);
   sleepContext.drawImage(sleepImage,f%4*384,Math.floor(f/4)*512,384,512,0,408-[476,475,476,475,384,384,384,384][f],384,512);
  }
  sleepLast=now;
 }else sleepLast=null;
 requestAnimationFrame(sleepTick);
}
requestAnimationFrame(sleepTick);
