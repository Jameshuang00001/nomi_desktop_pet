from pathlib import Path
import plistlib
import shutil
root=Path(__file__).resolve().parent.parent
app=root/'dist/糯米桌面宠物.app'
(app/'Contents/Resources').mkdir(parents=True,exist_ok=True)
(app/'Contents/MacOS').mkdir(parents=True,exist_ok=True)
s=(root/'assets/original-pet.html').read_text()
s=s.replace('奶盖','糯米')
s=s.replace('const pet=',(root/'naigai-desktop/gaze.js').read_text()+'\nlet sleeping=false,pottyActive=false,folderActive=false;\nconst pet=',1)
s=s.replace('function setState(i,hold=0){','function setState(i,hold=0){if(typeof sleeping!=="undefined"&&(sleeping||pottyActive||folderActive))return;cancelLook();',1)
s=s.replace('if(paused)return;draw(row,col)', 'if(paused||sleeping||pottyActive||folderActive)return;draw(row,col)')
s=s.replace('[280,110,110,140,140,320]', '[560,220,220,280,280,640]')
s=s.replace('</style>', '''
html,body{background:transparent!important;margin:0!important;overflow:hidden!important;min-height:0!important;width:180px;height:170px}
main{padding:0!important;margin:0!important;width:180px;height:170px}
main>small,main>h1,main>p,.controls,.tools,footer,.hint,.status{display:none!important}
.stage{position:absolute;inset:0;width:180px;height:170px;border:0!important;border-radius:0;background:transparent!important;overflow:visible}
.pet{left:-6px!important;top:-50px!important;scale:.7;filter:none}
</style>''',1)
a=s.index('pet.onpointerdown=');b=s.index("document.getElementById('pause').onclick",a)
s=s[:a]+'''const bridge=window.webkit.messageHandlers.pet;
pet.onpointerdown=e=>{if(e.button!==0)return;if(pottyActive)finishPotty();if(isLooking)setState(0);restUntil=performance.now()+6000;roamUntil=0;drag={x:e.screenX,y:e.screenY,moved:false};pet.setPointerCapture(e.pointerId);bridge.postMessage({action:'down',x:e.screenX,y:e.screenY})};
pet.addEventListener('pointermove',e=>{if(!drag)return;const dx=e.screenX-drag.x,dy=e.screenY-drag.y;if(Math.hypot(dx,dy)>4){drag.moved=true;bridge.postMessage({action:'move',x:e.screenX,y:e.screenY})}});
pet.onpointerup=()=>{const moved=drag?.moved;bridge.postMessage({action:'up'});setTimeout(()=>drag=null,0);if(moved){clearTimeout(clickTimer);setState(0)}};
pet.onpointercancel=()=>{drag=null;bridge.postMessage({action:'up'});setState(0)};
document.addEventListener('contextmenu',e=>{e.preventDefault();drag=null;restUntil=performance.now()+6000;roamUntil=0;bridge.postMessage({action:'menu'})});
''' +s[b:]
s=s.replace('</script>', (root/'naigai-desktop/roam.js').read_text()+(root/'naigai-desktop/sleep.js').read_text()+(root/'naigai-desktop/potty.js').read_text()+(root/'naigai-desktop/folder.js').read_text()+"\nfollow.checked=false;document.removeEventListener('pointermove',gaze);\n</script>")
(app/'Contents/Resources/pet.html').write_text(s)
shutil.copy2(root/'naigai-desktop/assets/sleep-sheet.png',app/'Contents/Resources/sleep-sheet.png')
for asset in ['potty-sheet.png','poop.png','folder-sheet.png']:shutil.copy2(root/'naigai-desktop/assets'/asset,app/'Contents/Resources'/asset)
(app/'Contents/Info.plist').write_bytes(plistlib.dumps({'NSAppleEventsUsageDescription':'允许糯米偶尔拖动附近桌面文件夹的图标位置，不移动文件夹内容。','CFBundleIconFile':'Nuomi.icns','CFBundleExecutable':'Naigai','CFBundleIdentifier':'local.james.nuomi.htmlpet','CFBundleName':'糯米桌面宠物','CFBundleDisplayName':'糯米桌面宠物','CFBundlePackageType':'APPL','CFBundleShortVersionString':'2.6.0','CFBundleVersion':'8','LSMinimumSystemVersion':'13.0','LSUIElement':True,'NSHighResolutionCapable':True}))
print(app)
