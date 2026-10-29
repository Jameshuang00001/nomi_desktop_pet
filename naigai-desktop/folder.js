const folderImage=new Image(),folderCanvas=document.createElement('canvas');
folderImage.src='folder-sheet.png';folderCanvas.width=384;folderCanvas.height=416;
folderCanvas.style.cssText='position:absolute;inset:0;width:192px;height:208px;display:none;pointer-events:none';pet.appendChild(folderCanvas);
const folderContext=folderCanvas.getContext('2d');
function beginFolder(){
 if(folderActive||sleeping||pottyActive||paused||drag||nativeHidden||locked||roamUntil||!folderImage.complete||!folderImage.naturalWidth)return false;
 folderActive=true;cancelLook();clearTimeout(timer);clearTimeout(release);clearTimeout(clickTimer);locked=true;roamUntil=0;pet.style.backgroundImage='none';folderCanvas.style.display='block';folderPose(1);return true;
}
function folderPose(f){
 if(!folderActive)return;
 folderContext.clearRect(0,0,384,416);
 // Remove the illustrative blue folder from the preview. Finder supplies the real icon.
 const cut=[305,311,288,295][f],top=366;
 const dy=408-[442,443,443,443][f];
 folderContext.drawImage(folderImage,f*384,0,384,top,0,dy,384,top);
 folderContext.drawImage(folderImage,f*384,top,cut,512-top,0,dy+top,cut,512-top);
}
function endFolder(){if(!folderActive)return;folderActive=false;folderCanvas.style.display='none';pet.style.backgroundImage=`url(${img})`;restUntil=performance.now()+4000;setState(0)}
