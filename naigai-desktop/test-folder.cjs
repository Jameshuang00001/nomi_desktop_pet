const vm=require('vm'),fs=require('fs'),assert=require('assert');
let draws=0;
const c={folderActive:false,sleeping:false,pottyActive:false,paused:false,drag:null,nativeHidden:false,locked:false,roamUntil:0,timer:0,release:0,clickTimer:0,img:'original',restUntil:0,Image:class{constructor(){this.complete=true;this.naturalWidth=1536}},pet:{style:{},appendChild(){}},document:{createElement:()=>({style:{},getContext:()=>({clearRect(){},drawImage(){draws++}})})},performance:{now:()=>10},cancelLook(){},clearTimeout(){},setState(){c.locked=false}};
vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/folder.js','utf8'),c);
for(const k of ['sleeping','pottyActive','paused','drag','nativeHidden','locked','roamUntil']){c[k]=true;assert(!c.beginFolder());c[k]=false}
assert(c.beginFolder());assert(c.folderActive);assert(!c.beginFolder());assert.equal(draws,0);c.folderPose(1);assert.equal(draws,2);c.folderPose(3);assert.equal(draws,4);c.endFolder();assert(!c.folderActive);assert.equal(c.pet.style.backgroundImage,'url(original)');
console.log('PASS: folder pose, mutual exclusion and original artwork restoration');
