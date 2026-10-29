const vm=require('vm'),fs=require('fs'),assert=require('assert');
let draws=0,states=[],raf;
const pet={style:{},dataset:{},appendChild(){},setAttribute(){}};
const c={sleeping:false,pet,img:'original',paused:false,nativeHidden:false,roamUntil:1,restUntil:0,timer:1,release:1,clickTimer:1,locked:false,
 Image:class{constructor(){this.complete=true;this.naturalWidth=1536}},document:{createElement:()=>({style:{},getContext:()=>({clearRect(){},drawImage(){draws++}})})},
 performance:{now:()=>0},cancelLook(){},clearTimeout(){},requestAnimationFrame(f){raf=f},setState(i){states.push(i);c.locked=false}};
vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/sleep.js','utf8'),c);
c.setSleeping(true);assert(c.sleeping);assert(c.locked);assert.equal(c.roamUntil,0);assert.equal(pet.style.backgroundImage,'none');
raf(0);for(let t=50;t<=650;t+=50)raf(t);assert.equal(draws,2);c.paused=true;raf(1300);assert.equal(draws,2);c.paused=false;
c.setSleeping(false);assert(!c.sleeping);assert.equal(pet.style.backgroundImage,'url(original)');assert.deepEqual(states,[0]);raf(2000);assert.equal(draws,2);
console.log('PASS: sleep stops locomotion; frame playback; pause; wake restores original atlas and idle.');
