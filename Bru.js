javascript:(function(){

const AppModes={AUTO:'auto',MANUAL:'manual',NORMAL:'normal',STORAGE_KEY:'typingAppMode'};
const Constants={
  TYPING:{CHARS_PER_WORD:5,MS_PER_MINUTE:60000},
  EVENTS:{
    MODE_CHANGE:'modeChange',METRICS_UPDATED:'metricsUpdated',SESSION_COMPLETED:'sessionCompleted',
    COUNTERS_INCREMENTED:'countersIncremented',MANUAL_SESSION_COMPLETED:'manualSessionCompleted',
    SESSION_COMPLETED_REFRESH:'sessionCompletedRefresh'
  },
  STORAGE:{
    WPM_SESSION_COUNT:'typingWpmSessionCount',ACCURACY_SESSION_COUNT:'typingAccuracySessionCount',
    ACCURACY_BUFFER_COUNT:'typingAccuracyBufferCount',DYNAMIC_WPM_VALUES:'dynamicWpmValues',
    DYNAMIC_ACCURACIES:'dynamicAccuracies'
  },
  BEHAVIOR:{
    MIN_DELAY_FACTOR:0.4,MAX_DELAY_FACTOR:1.8,WORD_BOUNDARY_MIN:1.05,WORD_BOUNDARY_MAX:0.1,
    COMMON_SEQ_MIN:0.85,COMMON_SEQ_MAX:0.05
  }
};
const AppConfig={
  _generateDynamicArray(key,count,min,max){
    let arr=JSON.parse(localStorage.getItem(key)||'null');
    if(!Array.isArray(arr)||arr.length!==count){
      arr=Array.from({length:count},()=>Math.floor(Math.random()*(max-min+1))+min);
      localStorage.setItem(key,JSON.stringify(arr));
    }
    return arr;
  },
  get wpmValues(){return this._generateDynamicArray(Constants.STORAGE.DYNAMIC_WPM_VALUES,10,100,125);},
  get accuracies(){return this._generateDynamicArray(Constants.STORAGE.DYNAMIC_ACCURACIES,10,95,99);},
  accuracyBuffers:[0.7,0.7,0.7,0.7,0.7,0,0,0,0,0],
  commonSequences:['th','he','in','er','an','en','ing','the','and'],
  wordBoundaries:[' ','.',',',';',':'],
  typingParams:{
    allowedDeviation:2,correctionStrength:0.8,humanVariationStrength:0.25,
    microPauseChance:0.06,burstChance:0.12,hesitationChance:0.05,maxMicroPause:200,
    feedbackInterval:800,wpmSmoothingFactor:0.6,overcompensationFactor:1.5,
    speedBoost:0.85,adaptationRate:0.2,earlyBoostFactor:0.7
  }
};

class EventBus{
  constructor(){this.events={};}
  on(e,l){(this.events[e]||(this.events[e]=[])).push(l);}
  emit(e,...a){(this.events[e]||[]).forEach(l=>l(...a));}
}

class Logger{
  static log(m,c=''){console.log((c?`[${c}] `:'')+m);}
}

class Storage{
  static get(k,d){return parseInt(localStorage.getItem(k)||d.toString());}
  static set(k,v){localStorage.setItem(k,v);}
  static inc(k,max,d=0){
    let v=this.get(k,d)+1;if(v>max){v=1;Logger.log(`Cycle ${k} reset`);}
    this.set(k,v);return v;
  }
}

class Utils{
  static delay(ms){return new Promise(r=>setTimeout(r,ms));}
  static getLongestWord(content){
    const words=content.split(/\s+/);
    let longest={word:'',index:0};
    words.forEach((w,i)=>{if(w.length>longest.word.length){longest.word=w;longest.index=content.indexOf(w);}});
    return longest;
  }
  static format(n,d=2){return n?.toFixed(d)||'0.00';}
  static rand(base,min,variance){return base*(min+Math.random()*variance);}
  static starts(str,arr){return arr.some(p=>str.startsWith(p));}
  static in(ch,arr){return arr.includes(ch);}
  static clamp(v,min,max){return Math.max(min,Math.min(max,v));}
  static async retry(fn,int=500){
    if(fn())return true;
    return new Promise(res=>{
      const id=setInterval(()=>{if(fn()){clearInterval(id);res(true);}},int);
    });
  }
}

class ConfigService{
  constructor(bus){this.bus=bus;this.load();}
  load(){
    this._mode=localStorage.getItem(AppModes.STORAGE_KEY)||AppModes.AUTO;
    this.wc=Storage.get(Constants.STORAGE.WPM_SESSION_COUNT,1);
    this.ac=Storage.get(Constants.STORAGE.ACCURACY_SESSION_COUNT,1);
    this.bc=Storage.get(Constants.STORAGE.ACCURACY_BUFFER_COUNT,1);
    this.tp=AppConfig.typingParams;
  }
  set mode(v){this._mode=v;localStorage.setItem(AppModes.STORAGE_KEY,v);this.bus.emit(Constants.EVENTS.MODE_CHANGE,v);}
  get mode(){return this._mode;}
  get isAuto(){return this.mode===AppModes.AUTO;}
  get isManual(){return this.mode===AppModes.MANUAL;}
  get isNormal(){return this.mode===AppModes.NORMAL;}
  get targetWPM(){return AppConfig.wpmValues[this.wc-1];}
  get targetAcc(){return AppConfig.accuracies[this.ac-1];}
  get targetBuf(){return AppConfig.accuracyBuffers[this.bc-1];}
  increment(){
    if(this.isNormal)return;
    this.wc=Storage.inc(Constants.STORAGE.WPM_SESSION_COUNT,AppConfig.wpmValues.length);
    this.ac=Storage.inc(Constants.STORAGE.ACCURACY_SESSION_COUNT,AppConfig.accuracies.length);
    this.bc=Storage.inc(Constants.STORAGE.ACCURACY_BUFFER_COUNT,AppConfig.accuracyBuffers.length);
    if(this.wc===1){localStorage.removeItem(Constants.STORAGE.DYNAMIC_WPM_VALUES);localStorage.removeItem(Constants.STORAGE.DYNAMIC_ACCURACIES);}
    this.bus.emit(Constants.EVENTS.COUNTERS_INCREMENTED,{wpm:this.wc,acc:this.ac,buf:this.bc});
  }
}

class DOM{
  static getNode(){
    try{return Object.values(document.querySelector("div.dash-copyContainer"))[1].children._owner.stateNode;}catch{return null;}
  }
}

class Metrics{
  constructor(cfg,bus){this.cfg=cfg;this.bus=bus;this.reset();}
  reset(){
    this.total=0;this.correct=0;this.start=null;this.chars=0;this.wpm=0;this.smooth=0;
    this.delay=60000/(this.cfg.targetWPM*5)*this.cfg.typingParams.speedBoost;
    this.last=0;this.cumulative=0;this.history=[];this.offset=0;this.startupCount=0;this.startupDone=false;this.boosted=false;this.done=false;
  }
  get acc(){return this.total>0?this.correct/this.total*100:100;}
  stroke(ok){
    this.total++;if(ok)this.correct++;
    if(!this.start)this.start=Date.now();
    this.chars++;
    const min=(Date.now()-this.start)/60000;
    if(min>0){
      const instant=this.chars/5/min;
      this.smooth=this.smooth===0?instant:this.smooth*0.6+instant*0.4;
      this.wpm=this.smooth;
      this.log();
    }
  }
  log(){
    if(Date.now()-this.last>800){
      Logger.log(`WPM: ${Utils.format(this.wpm)} (Target: ${this.cfg.targetWPM})`);
      this.last=Date.now();this.adjust();this.pushHistory();
    }
    this.startup();
  }
  adjust(){
    const diff=this.wpm-this.cfg.targetWPM;
    if(Math.abs(diff)<=2)return;
    Logger.log(`${diff<0?'SLOW':'FAST'}: ${Utils.format(Math.abs(diff))} WPM`);
    if(this.history.length>=5){
      const avg=this.history.slice(-5).reduce((a,b)=>a+b,0)/5;
      const dev=avg-this.cfg.targetWPM;
      if(Math.abs(dev)>2){this.offset+=-dev*0.015;Logger.log(`Delay offset: ${Utils.format(this.offset)}ms`);}
    }
  }
  startup(){
    if(this.startupDone)return;
    this.startupCount++;
    if(this.startupCount===10&&!this.boosted&&this.wpm<this.cfg.targetWPM*0.9){
      this.delay*=0.7;this.boosted=true;Logger.log("Startup boost applied");
    }
    if(this.startupCount>=30){this.startupDone=true;Logger.log("Startup phase complete");}
  }
  pushHistory(){this.history.push(this.wpm);if(this.history.length>10)this.history.shift();}
  finish(){if(this.done)return;this.done=true;this.bus.emit(Constants.EVENTS.SESSION_COMPLETED,{finalWPM:this.wpm,finalAcc:this.acc});}
}

class Timing{
  constructor(m,cfg){this.m=m;this.cfg=cfg;}
  next(content,idx){
    let delay=this.m.delay;
    const now=Date.now();
    if(!this.m.startupDone)delay*=this.cfg.typingParams.earlyBoostFactor;
    if(this.m.chars>5&&this.m.wpm>0)delay=this.adjust(delay);
    delay*=this.human(content,idx);
    delay=Utils.clamp(delay,this.m.delay*0.4,this.m.delay*1.8);
    this.m.delay=delay;this.m.last=now;
    return delay;
  }
  adjust(d){
    let diff=this.m.wpm-this.cfg.targetWPM;
    let corr=diff*this.cfg.typingParams.correctionStrength;
    if(diff<0)corr*=this.cfg.typingParams.overcompensationFactor;
    d+=corr+this.m.offset;
    this.m.cumulative+=diff*this.cfg.typingParams.adaptationRate;
    return this.trend(d,diff);
  }
  trend(d,diff){
    if(this.m.chars%3===0&&Math.abs(this.m.cumulative)>0.5){
      d*=1+this.m.cumulative*0.02;
      if(Math.abs(this.m.cumulative)>3)this.m.cumulative*=0.7;
    }
    if(this.m.history.length>=3){
      const avg=this.m.history.slice(-3).reduce((a,b)=>a+b,0)/3;
      const dev=avg-this.cfg.targetWPM;
      if(Math.abs(dev)>2&&Math.sign(dev)===Math.sign(diff))d*=1-dev*0.01;
    }
    return d;
  }
  human(s,i){
    let f=0.9+Math.random()*0.2;
    const r=Math.random();
    if(r<0.06)f*=1+Math.random()*0.3;
    else if(r<0.18)f*=0.75+Math.random()*0.1;
    else if(r<0.23)f*=1.1+Math.random()*0.4;
    const ch=s[i];
    if(Utils.in(ch,AppConfig.wordBoundaries))return Utils.rand(f,1.05,0.1);
    if(Utils.starts(s.slice(i,i+3),AppConfig.commonSequences))return Utils.rand(f,0.85,0.05);
    return f;
  }
}

class Accuracy{
  constructor(m,cfg){this.m=m;this.cfg=cfg;this.buf=AppConfig.accuracyBuffers[Storage.get(Constants.STORAGE.ACCURACY_BUFFER_COUNT,1)-1];}
  getBufferInfo(){return`+${this.buf.toFixed(2)}%`;}
  shouldErr(){const target=this.cfg.targetAcc+this.buf;return this.m.total>0&&(this.m.acc>target||Math.random()>target/100);}
}

class Keyboard{
  constructor(m,cfg,bus){this.m=m;this.cfg=cfg;this.bus=bus;}
  stroke(node,ok){ok?this.m.stroke(true):this.m.stroke(false);node.handleKeyPress("character",new KeyboardEvent("keypress",{key:ok?node.props.lessonContent[node.typedIndex]:"$"}));}
  enter(node){node.handleKeyPress("character",new KeyboardEvent("keypress",{key:"\n"}));}
  make(type,node,acc,longest){
    return(evt,ke)=>{
      if(type==="character"){
        if(node.typedIndex===longest.index){this.enter(node);return;}
        this.stroke(node,!acc.shouldErr());
      }else if(ke.key==="\n")this.enter(node);
    };
  }
  countdown(orig){
    return(type,ke)=>{
      if(type==="character"){
        if(ke.key==="a")this.cfg.mode=AppModes.AUTO;
        else if(ke.key==="m")this.cfg.mode=AppModes.MANUAL;
        else if(ke.key==="n")this.cfg.mode=AppModes.NORMAL;
      }
      if(ke.key>="1"&&ke.key<="8"||ke.key==="Shift"||ke.key==="Control")return orig(type,ke);
    };
  }
}

class Session{
  constructor(cfg,m,bus){this.cfg=cfg;this.m=m;this.bus=bus;bus.on(Constants.EVENTS.SESSION_COMPLETED,d=>this.handle(d));}
  handle(d){
    const tw=this.cfg.targetWPM,ta=this.cfg.targetAcc,fw=d?.finalWPM||0,fa=d?.finalAcc||0;
    Logger.log(`Final WPM: ${Utils.format(fw)} (Target: ${tw})`);
    Logger.log(`Final Acc: ${Utils.format(fa)}% (Target: ${ta}%)`);
    this.cfg.increment();
    Logger.log("Race complete. No refresh.");
  }
}

class AutoTyper{
  constructor(svc){Object.assign(this,svc);}
  async init(){await Utils.retry(()=>this.start(),500);}
  start(){
    try{
      this.node=DOM.getNode();if(!this.node)return false;
      this.content=this.node.props.lessonContent;
      this.longest=Utils.getLongestWord(this.content);
      this.orig=this.node.input.keyHandler;
      this.m=new Metrics(this.cfg,this.bus);
      this.t=new Timing(this.m,this.cfg);
      this.a=new Accuracy(this.m,this.cfg);
      this.k=new Keyboard(this.m,this.cfg,this.bus);
      this.s=new Session(this.cfg,this.m,this.bus);
      Logger.log("Script loaded");
      Logger.log(`Session: ${this.cfg.targetWPM} WPM | ${this.cfg.targetAcc}% acc`);
      this.launch();return true;
    }catch{return false;}
  }
  async launch(){
    const fnNorm=this.k.make("character",this.node,this.a,this.longest);
    const fnCount=this.k.countdown(this.orig);
    this.node.input.keyHandler=fnCount;
    Logger.log("Press: a=auto m=manual n=normal");Logger.log("Starting in 4s...");
    await Utils.delay(4000);
    if(this.cfg.isNormal){this.node.input.keyHandler=this.orig;Logger.log("Normal mode – script disabled");return;}
    this.node.input.keyHandler=fnNorm;
    if(this.cfg.isAuto){Logger.log(`Auto typing – WPM: ${this.cfg.targetWPM}`);this.run();}else Logger.log(`Manual typing – Acc: ${this.cfg.targetAcc}%`);
  }
  async run(){
    let idx=0;
    const next=async()=>{
      if(this.cfg.mode!==AppModes.AUTO||this.node.typedIndex>=this.content.length){
        if(this.node.typedIndex>=this.content.length)this.m.finish();
        return;
      }
      const delay=this.t.next(this.content,this.node.typedIndex);
      await Utils.delay(delay);
      if(this.cfg.mode!==AppModes.AUTO)return;
      if(this.node.typedIndex===this.longest.index)this.k.enter(this.node);
      else this.k.stroke(this.node,!this.a.shouldErr());
      next();
    };
    next();
  }
}

class Container{
  constructor(){
    this.bus=new EventBus();
    this.cfg=new ConfigService(this.bus);
    this.m=new Metrics(this.cfg,this.bus);
    this.t=new Timing(this.m,this.cfg);
    this.a=new Accuracy(this.m,this.cfg);
    this.k=new Keyboard(this.m,this.cfg,this.bus);
    this.s=new Session(this.cfg,this.m,this.bus);
    this.typer=new AutoTyper({bus:this.bus,cfg:this.cfg,m:this.m,t:this.t,a:this.a,k:this.k,s:this.s});
  }
  start(){this.typer.init();}
}

(new Container()).start();

})();
