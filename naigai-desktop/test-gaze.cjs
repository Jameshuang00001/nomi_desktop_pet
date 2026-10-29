const vm=require('vm'),fs=require('fs'),assert=require('assert');
let timeout,frames=[],now=0,delay;
const c={paused:false,locked:false,drag:null,nativeHidden:false,roamUntil:0,timer:1,restUntil:0,Math,performance:{now:()=>now},clearTimeout(){timeout=null},setTimeout(f,ms){timeout=f;delay=ms;return 2},draw(r,k){frames.push([r,k])},setState(i){c.locked=false;c.cancelLook();frames.push(['idle',i])}};vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/gaze.js','utf8'),c);
assert.equal(c.updateLook(100,0),false);assert(c.occasionalLook(100,0,4000));assert.equal(delay,4000);assert.deepEqual(frames.at(-1),[9,4]);
assert(c.updateLook(-100,0));assert.deepEqual(frames.at(-1),[10,4]);assert(c.updateLook(0,-100));assert.deepEqual(frames.at(-1),[9,0]);
let n=frames.length;c.updateLook(0,-100);assert.equal(frames.length,n);assert.equal(c.occasionalLook(100,0),false);
timeout();assert.deepEqual(frames.at(-1),['idle',0]);assert.equal(c.updateLook(100,0),false);
assert(c.occasionalLook(100,0));c.drag={};assert.equal(c.updateLook(-100,0),false);assert.equal(timeout,null);c.drag=null;
for(const key of ['paused','locked','drag','nativeHidden','roamUntil']){c[key]=true;assert.equal(c.occasionalLook(100,0),false);c[key]=false}
console.log('PASS: active-session right/left/up tracking; no redundant redraw; timed stop; no tracking outside session; interruption guards.');
