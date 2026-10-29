const vm=require('vm'),fs=require('fs'),assert=require('assert');
let events=[],raf,now=0;
const c={pottyActive:false,sleeping:false,paused:false,nativeHidden:false,drag:null,locked:false,roamUntil:0,timer:0,release:0,clickTimer:0,img:'original',restUntil:0,
 pet:{style:{},appendChild(){}},Image:class{constructor(){this.complete=true;this.naturalWidth=1536}},document:{createElement:()=>({style:{},getContext:()=>({clearRect(){},drawImage(){}})})},performance:{now:()=>now},clearTimeout(){},cancelLook(){},requestAnimationFrame(f){raf=f},setState(){c.locked=false},bridge:{postMessage(e){events.push(e.action)}}};
vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/potty.js','utf8'),c);
for(const key of ['sleeping','paused','nativeHidden','drag','locked','roamUntil']){c[key]=true;assert.equal(c.startPotty(),false);c[key]=false}
assert(c.startPotty());assert(!c.startPotty());for(now=0;now<=5100;now+=50)raf(now);
assert.deepEqual(events,['dropping','pottyFinished']);assert(!c.pottyActive);assert.equal(c.pet.style.backgroundImage,'url(original)');
events=[];assert(c.startPotty());raf(6000);c.finishPotty();assert.deepEqual(events,['pottyFinished']);
events=[];assert(c.startPotty());c.paused=true;for(now=0;now<6000;now+=50)raf(now);assert.equal(events.length,0);c.paused=false;c.finishPotty();
console.log('PASS: blocked during sleep/actions; one deposit per cycle; cancellation; pause; restores original artwork.');
