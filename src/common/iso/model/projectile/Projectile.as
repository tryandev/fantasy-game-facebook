package common.iso.model.projectile
{
	import com.raka.commands.interfaces.ICommand;
	import com.raka.loader.IRakaBatchLoadItem;
	import com.raka.loader.IRakaLoadItem;
	import com.raka.loader.RakaBatchLoadItem;
	import com.raka.loader.RakaLoadPriorities;
	import com.raka.loader.RakaLoadService;
	import com.raka.loader.RakaLoadSound;
	import com.raka.loader.events.RakaLoadErrorEvent;
	import com.raka.loader.events.RakaLoadEvent;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.proxy.IResponder;
	
	import common.iso.control.cmd.IsoCommandLoadAsset;
	import common.iso.model.IsoModel;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;

	public class Projectile
	{
		public static var MC_LINKAGENAME_START:String = 'spawn';
		public static var MC_LINKAGENAME_MIDDLE:String = 'projectile';
		public static var MC_LINKAGENAME_END:String = 'explosion';
		
		private static var loadedSounds:Object = new Object();
		
		public var cacheKey:String;
		public var name:String;
		public var swf:String;
		public var maxRange:int;
		public var speed:Number;
		public var motion:int;
		public var shake:String;
		public var soundSpawn:String = '';
		public var soundFly:String = '';
		public var soundHit:String = '';
		public var offsetX:Number;
		public var offsetY:Number;
		
		public var mcStart:MovieClip;		// the spawning effect. e.g can be the bullet's shell being ejected
		public var mcMiddle:MovieClip;		// the actual projectile. e.g. the bullet
		public var mcEnd:MovieClip;			// the hit effect. e.g. the blood splash or glass shatter
		
		private var _commandLoadSWF:ICommand;
		private var _soundBatchLoader:IRakaBatchLoadItem;
		
		private var _loadedSWF:Boolean;
		private var _loadedSounds:Boolean;
		
		private var _loadSuccess:Function;
		private var _loadFailure:Function;
		
		private var _url:String;
		
		public var parent:Projectile;
		public var failedSWF:Boolean;
		
		public function clone():Projectile
		{
			var projectile:Projectile = new Projectile();
			
			projectile.cacheKey = cacheKey;
			projectile.name = name;
			projectile.swf = swf;
			projectile.maxRange = maxRange;
			projectile.speed = speed;
			projectile.motion = motion;
			projectile.shake = shake;
			projectile.soundSpawn = soundSpawn;
			projectile.soundFly = soundFly;
			projectile.soundHit = soundHit;
			projectile.offsetX = offsetX;
			projectile.offsetY = offsetY;
			projectile.parent = this;
			return projectile;
		}
		
		public function dispose():void
		{
			parent = null;
			if (mcStart)
			{
				mcStart.stop();
				mcStart = null;
			}
			
			if (mcMiddle)
			{
				mcMiddle.stop();
				mcMiddle = null;
			}
			
			if (mcEnd)
			{
				mcEnd.stop();
				mcEnd = null;
			}
			
			if (_commandLoadSWF)
			{
				_commandLoadSWF.dispose();
				_commandLoadSWF = null;
			}
			
			if (_soundBatchLoader)
			{
				_soundBatchLoader.removeEventListener(RakaLoadEvent.LOAD_COMPLETE, onSoundsLoaded);
				_soundBatchLoader.removeEventListener(RakaLoadErrorEvent.LOAD_ERROR, onSoundsLoadFail);
				_soundBatchLoader.dispose();
				_soundBatchLoader = null;
			}
			
			_loadFailure = null;
			_loadSuccess = null;
		}
		
		public function toString():String
		{
			// use the getter
			return "[Projectile: " + url + "]";
		}
		
		public function get url():String
		{
			if (_url == null) _url = IsoModel.gi.getProjectileAssetsUrl(swf)
			
			return _url;
		}
		
		public function get hasLoaded():Boolean
		{
			return _loadedSWF && _loadedSounds;
		}
		
		public function loadAssets(onSuccess:Function, onFailure:Function):void
		{
			if (hasLoaded)
			{
				onSuccess.call(null, this);
			}
			else
			{
				_loadSuccess = onSuccess;
				_loadFailure = onFailure;
				
				loadImages();
				loadSounds();
			}
		}
		
		private function loadImages():void
		{
			_loadedSWF = false;
			
			_commandLoadSWF = new IsoCommandLoadAsset(url, onImagesLoaded, onImagesLoadFail);
			_commandLoadSWF.execute();
		}
		
		private function loadSounds():void
		{
			_loadedSounds = false;
			
			var soundLoader:IRakaLoadItem;
			var soundBatch:Array = [];
			var lloadedSounds:Object = loadedSounds;
			
			if (soundSpawn.length && lloadedSounds[soundSpawn] != 1)
			{
				soundLoader = new RakaLoadSound(IsoModel.gi.getSoundsUrl(soundSpawn), RakaLoadPriorities.ULTRA_IMMEDIATE_PRIORITY);
				soundBatch.push(soundLoader);
				RakaSoundManager.getInstance().monitorPreload(soundLoader);
				loadedSounds[soundSpawn] = 1;
			}
			
			if (soundFly.length && lloadedSounds[soundFly] != 1)
			{
				soundLoader = new RakaLoadSound(IsoModel.gi.getSoundsUrl(soundFly), RakaLoadPriorities.ULTRA_IMMEDIATE_PRIORITY);
				soundBatch.push(soundLoader);
				RakaSoundManager.getInstance().monitorPreload(soundLoader);
				loadedSounds[soundFly] = 1;
			}
			
			if (soundHit.length && lloadedSounds[soundHit] != 1)
			{
				soundLoader = new RakaLoadSound(IsoModel.gi.getSoundsUrl(soundHit), RakaLoadPriorities.ULTRA_IMMEDIATE_PRIORITY);
				soundBatch.push(soundLoader);
				RakaSoundManager.getInstance().monitorPreload(soundLoader);
				loadedSounds[soundHit] = 1;
			}
			
			if (soundBatch.length) {
				_soundBatchLoader = new RakaBatchLoadItem(soundBatch);
				_soundBatchLoader.addEventListener(RakaLoadEvent.LOAD_COMPLETE, onSoundsLoaded);
				_soundBatchLoader.addEventListener(RakaLoadErrorEvent.LOAD_ERROR, onSoundsLoadFail);
				RakaLoadService.getInstance().load(_soundBatchLoader);
			} else {
				onSoundsLoaded(null);
			}
		}
		
		private function onImagesLoaded(e:ICommand):void
		{
			_loadedSWF = true;
			// ARAY - this is causing the duplicates to stop -- there's a bigger planning issue here - should commands dispose themselves? Or should the dispose of loaders have cancels in them (yes.. but in all cases)?
//			if (_commandLoadSWF) {
//				_commandLoadSWF.dispose();
//				_commandLoadSWF = null;
//			}
			if (_loadedSounds)
			{
				assetsLoadSuccess();
			}
		}
		
		private function onImagesLoadFail(e:ICommand):void
		{
			_loadedSWF = true;
			failedSWF = true;
			assetsLoadFail();
		}
		
		private function onSoundsLoaded(e:RakaLoadEvent):void
		{
			_loadedSounds = true;
			
			if (_loadedSWF)
			{
				assetsLoadSuccess();
			}
		}
		
		private function onSoundsLoadFail(e:RakaLoadErrorEvent):void
		{
			_loadedSounds = true;
			assetsLoadFail();
		}
		
		private function assetsLoadSuccess():void
		{
			if (IsoModel.gi.hasCachedAsset(Projectile.MC_LINKAGENAME_START, url)) {
				var classProjectileStart:Class = IsoModel.gi.getCachedAsset(Projectile.MC_LINKAGENAME_START, url);
				mcStart = MovieClip(new classProjectileStart());
				mcStart.stop();
			}
			
			if (IsoModel.gi.hasCachedAsset(Projectile.MC_LINKAGENAME_MIDDLE, url)) {
				var classProjectileMiddle:Class = IsoModel.gi.getCachedAsset(Projectile.MC_LINKAGENAME_MIDDLE, url);
				mcMiddle = MovieClip(new classProjectileMiddle());	
				mcMiddle.stop();			
			}
			
			if (IsoModel.gi.hasCachedAsset(Projectile.MC_LINKAGENAME_END, url)) {
				var classProjectileEnd:Class = IsoModel.gi.getCachedAsset(Projectile.MC_LINKAGENAME_END, url);
				mcEnd = MovieClip(new classProjectileEnd());		
				mcEnd.stop();		
			}
			
			_loadSuccess.call(null, this);
		}
		
		private function assetsLoadFail():void
		{
			_loadFailure.call(null, this);
		}
		
		public function drawDefaultMCs(forceDraw:Boolean = false):void 
		{
			if (forceDraw)  
			{
				_loadedSWF = true;
				_loadedSounds = true;
			} 
			else if (mcStart || mcMiddle || mcEnd) 
			{
				return;
			}
			
			mcStart = null;
			mcEnd = null;
			mcMiddle = new MovieClip();	
			var g:Graphics = mcMiddle.graphics;
			var yOffset:Number = 0;
			g.beginFill(0xFFFF44, 0.75);
			g.moveTo( 0, 1	+ yOffset);
			g.lineTo( 0, 5	+ yOffset);
			g.lineTo(20, 0	+ yOffset);
			g.lineTo( 0, -5	+ yOffset);
			g.lineTo( 0, -1	+ yOffset);
			g.lineTo(-40,-1	+ yOffset);
			g.lineTo(-50,-6	+ yOffset);
			g.lineTo(-70,-6	+ yOffset);
			g.lineTo(-60, 0 + yOffset);
			g.lineTo(-70, 6	+ yOffset);
			g.lineTo(-50, 6	+ yOffset);
			g.lineTo(-40, 1	+ yOffset);
			g.lineTo(  0, 1 + yOffset);
			g.endFill();
		}
	}
}