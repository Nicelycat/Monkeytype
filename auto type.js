javascript:(function(){
/* ==== CONFIG (keeps <= 175 WPM to avoid Monkeytype outlier flag) ==== */
const MIN=16,MAX=19;
/* =================================================================== */
let running=0,btn=document.createElement('button');
btn.textContent='▶';btn.style.cssText='position:fixed;right:12px;bottom:12px;width:48px;height:48px;border:none;border-radius:50%;background:#444;color:#eee;font-size:24px;line-height:48px;text-align:center;z-index:9999;cursor:pointer;box-shadow:0 2px 6px rgba(0,0,0,.4)';
document.body.appendChild(btn);
btn.onclick=()=>{running=!running;btn.textContent=running?'■':'▶';btn.style.background=running?'#4caf50':'#444'};
function rand(min,max){return Math.floor(Math.random()*(max-min+1)+min)}
function nextChar(){const w=document.querySelector('.word.active');if(!w)return' ';for(const l of w.children)if(!l.className)return l.textContent;return' '}
function typeKey(k){const i=document.getElementById('wordsInput');if(!i)return;i.value+=k;i.dispatchEvent(new InputEvent('beforeinput',{data:k,inputType:'insertText'}));i.dispatchEvent(new InputEvent('input',{data:k,inputType:'insertText'}));i.dispatchEvent(new KeyboardEvent('keyup',{key:k}))}
function tick(){if(!running){requestAnimationFrame(tick);return}const k=nextChar();if(k){typeKey(k)}setTimeout(()=>requestAnimationFrame(tick),rand(MIN,MAX))}
const ready=setInterval(()=>{if(document.getElementById('wordsInput')&&document.querySelector('.word')){clearInterval(ready);tick()}},500)})();
