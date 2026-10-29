// Occasional tracking sessions: direction updates during the session only.
let lookTimer=0,isLooking=false,lastLookDirection=-1;
function cancelLook(){clearTimeout(lookTimer);lookTimer=0;isLooking=false;lastLookDirection=-1}
function stopLooking(){if(isLooking)setState(0)}
function updateLook(dx,dy){
 if(!isLooking)return false;
 if(paused||drag||nativeHidden||roamUntil){stopLooking();return false}
 if(Math.hypot(dx,dy)<20)return true;
 const angle=(Math.atan2(dx,-dy)*180/Math.PI+360)%360;
 const k=Math.round(angle/22.5)%16;
 if(k!==lastLookDirection){draw(9+Math.floor(k/8),k%8);lastLookDirection=k}
 return true;
}
function occasionalLook(dx,dy,duration=3000+Math.random()*2000){
 if(paused||locked||drag||nativeHidden||roamUntil||isLooking||Math.hypot(dx,dy)<35)return false;
 clearTimeout(timer);timer=0;locked=true;isLooking=true;
 updateLook(dx,dy);
 restUntil=Math.max(restUntil,performance.now()+duration+500);
 lookTimer=setTimeout(stopLooking,duration);
 return true;
}
