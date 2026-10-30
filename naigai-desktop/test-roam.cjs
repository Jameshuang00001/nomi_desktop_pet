const fs=require('fs'),vm=require('vm'),assert=require('assert');
let next,now=0,steps=[];const c={performance:{now:()=>now},Math,paused:false,drag:null,locked:false,row:0,setState(i){c.row=i;c.locked=i!==0},bridge:{postMessage(m){steps.push(m)}},requestAnimationFrame(f){next=f}};vm.createContext(c);vm.runInContext(fs.readFileSync(__dirname+'/roam.js','utf8'),c);
function run(seconds){for(let i=0;i<seconds*60;i++){now+=1000/60;next(now)}}
run(3);assert.equal(steps.length,0);run(3);assert(steps.length>0);assert(steps.every(s=>s.action==='step'&&Math.hypot(s.dx,s.dy)<=.601));
c.paused=true;let count=steps.length;run(1);assert.equal(steps.length,count);c.paused=false;
c.setRoaming(false);run(3);assert.equal(steps.length,count);c.setRoaming(true);run(3);assert(steps.length>count);
c.reverseRoaming(1);count=steps.length;run(.5);assert(steps.slice(count).every(s=>s.dx>=0));
console.log('PASS: idle delay, bounded time-based travel, pause, toggle, edge direction.');

assert(steps.some(s=>Math.abs(s.dy)>.01));
c.reverseVertical(-1);count=steps.length;run(.5);assert(steps.slice(count).length>0);assert(steps.slice(count).every(s=>s.dy<0));
c.reverseVertical(1);count=steps.length;run(.5);assert(steps.slice(count).length>0);assert(steps.slice(count).every(s=>s.dy>0));
assert(steps.some(s=>Math.hypot(s.dx,s.dy)>.59));
console.log('PASS: vertical travel, both vertical edge directions, normalized 36pt/s speed');
