package common.iso.view.display
{
	import com.raka.crimetown.util.debug.BuildDetails;
	import com.raka.iso.map.MapConfig;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.ai.IMover;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverFactory;
	import common.iso.control.audio.FrameLabelSound;
	import common.iso.model.FrameAction;
	import common.iso.view.containers.IsoMap;
	
	import flash.display.MovieClip;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	public class IsoCharacter extends IsoState
	{
		
		public static const ANI_ARRAY_IDLE:String = 'aniArrayIdle';
		public static const ANI_ARRAY_WALK:String = 'aniArrayWalk';
		public static const ANI_ARRAY_ATTACK:String = 'aniArrayAttack';
		public static const ANI_ARRAY_HIT:String = 'aniArrayHit';
		public static const ANI_ARRAY_DODGE:String = 'aniArrayDodge';
		public static const ANI_ARRAY_DEATH:String = 'aniArrayDeath';
		
		private const OVERLAY_PADDING:int = 20;
		
		private var _wholeSortY:int;
		private var _frameCount:Number = 0;
		private var _dX:int;
		private var _dY:int;
		
		
		protected var _liveMC:MovieClip;
		protected var _characterMover:MoverCharacter;
		protected var _aniArrs:Object;
		protected var _aniArrCurrent:String;
		protected var _actions:IsoFrameActions;
		
		
		public function IsoCharacter()
		{
			super();
			
			_characterMover = MoverFactory.getInstance().createMoverFor(this);
			
			_isoSize = 1;
			_aniArrs = new Object();
			_aniArrs[ANI_ARRAY_IDLE] = [];
			_aniArrs[ANI_ARRAY_WALK] = [];
			//_aniArrs[ANI_ARRAY_WALKSLOW] = [];
			_aniArrs[ANI_ARRAY_ATTACK] = [];
			_aniArrs[ANI_ARRAY_HIT] = [];
			_aniArrs[ANI_ARRAY_DODGE] = [];
			_aniArrs[ANI_ARRAY_DEATH] = [];
			redraw();
		}
		
		public override function dispose():void
		{
			for (var key:String in _aniArrs)
				delete _aniArrs[key];
			
			if (_characterMover)
			{
				_characterMover.dispose();
				_characterMover = null;
			}
			
			try
			{
				removeAsset(_liveMC);
				_liveMC = null;
			}
			catch (err:Error) {}
			
			super.dispose();
		}
		
		public function getHitMC():MovieClip
		{
			if (_aniArrs[ANI_ARRAY_HIT] && _aniArrs[ANI_ARRAY_HIT].length)
				return _aniArrs[ANI_ARRAY_HIT][_aniArrs[ANI_ARRAY_HIT].length - 1];
			
			return null;
		}
		
		public function get hasFightAsset():Boolean
		{	
			return hasAttackAsset && hasHitAsset;
		}	
		
		public function get hasAttackAsset():Boolean
		{
			return _aniArrs[ANI_ARRAY_ATTACK].length != 0;
		}	
		
		public function get hasHitAsset():Boolean
		{
			return _aniArrs[ANI_ARRAY_HIT].length != 0;
		}	
		
		public function get hasDodgeAsset():Boolean
		{
			return _aniArrs[ANI_ARRAY_DODGE].length != 0;
		}	
		
		public function get hasDeathAsset():Boolean
		{
			return _aniArrs[ANI_ARRAY_DEATH].length != 0;
		}	

		
		public override function get occupy():Boolean
		{
			return false;
		}
		
		public function rotate():void
		{
			// this should only be used for profile preview
			if (_dX ==  1 && _dY ==  1) {_dX =  1; _dY =  0; /*trace('avatar rotate 1');*/ }
			else if (_dX ==  1 && _dY ==  0) {_dX =  1; _dY = -1; /*trace('avatar rotate 2');*/ }
			else if (_dX ==  1 && _dY == -1) {_dX =  0; _dY = -1; /*trace('avatar rotate 3');*/ }
			else if (_dX ==  0 && _dY == -1) {_dX = -1; _dY = -1; /*trace('avatar rotate 4');*/ }
			else if (_dX == -1 && _dY == -1) {_dX = -1; _dY =  0; /*trace('avatar rotate 5');*/ }
			else if (_dX == -1 && _dY ==  0) {_dX = -1; _dY =  1; /*trace('avatar rotate 6');*/ }
			else if (_dX == -1 && _dY ==  1) {_dX =  0; _dY =  1; /*trace('avatar rotate 7');*/ }
			else if (_dX ==  0 && _dY ==  1) {_dX =  1; _dY =  1; /*trace('avatar rotate 8');*/ }
			else { /*trace('existing dXdY not found');*/ }
			
			changeSprite(_dX, _dY, _aniArrCurrent, true); 
		}
		
		private function getScaledMC(aniArr:Array):MovieClip
		{
			var newMC:MovieClip;
			
			if (aniArr == _aniArrs[ANI_ARRAY_ATTACK] || aniArr == _aniArrs[ANI_ARRAY_HIT] || aniArr == _aniArrs[ANI_ARRAY_DODGE] || aniArr == _aniArrs[ANI_ARRAY_DEATH])
			{
				newMC = getCharacterClip(aniArr, 0);
				newMC.scaleX = -_dY;
				newMC.gotoAndStop(0);
				return newMC;
			}
		
			if (_dX ==  1 && _dY ==  1) { newMC = getCharacterClip(aniArr, 0); newMC.scaleX =  1; } // S
			if (_dX ==  1 && _dY ==  0) { newMC = getCharacterClip(aniArr, 1); newMC.scaleX =  1; } // SE
			if (_dX ==  1 && _dY == -1) { newMC = getCharacterClip(aniArr, 2); newMC.scaleX =  1; } // E
			if (_dX ==  0 && _dY == -1) { newMC = getCharacterClip(aniArr, 3); newMC.scaleX =  1; } // NE
			if (_dX == -1 && _dY == -1) { newMC = getCharacterClip(aniArr, 4); newMC.scaleX =  1; } // N
			if (_dX == -1 && _dY ==  0) { newMC = getCharacterClip(aniArr, 3); newMC.scaleX = -1; } // NW
			if (_dX == -1 && _dY ==  1) { newMC = getCharacterClip(aniArr, 2); newMC.scaleX = -1; } // W
			if (_dX ==  0 && _dY ==  1) { newMC = getCharacterClip(aniArr, 1); newMC.scaleX = -1; } // SW
			
			return newMC;
		}
		
		private function getCharacterClip(arr:Array, index:int):MovieClip
		{
			var clip:MovieClip = arr[index] as MovieClip;
			var idleClips:Array = _aniArrs[ANI_ARRAY_IDLE];
			if (clip == null && BuildDetails.isProd)  {
				Log.error(this, "Cannot find item in animation array with index: " + index + ", using 0");
				clip = arr[0];
				
				if(clip == null) { 
					Log.error(this, "Cannot find item in animation array with index: 0");
					clip = idleClips[index] as MovieClip;
					
					if(clip == null && idleClips.length)
					{
						clip = idleClips[idleClips.length - 1] as MovieClip;
					}
				}
				
				if (clip == null)
				{
					Log.error(this, "Cannot find an idle replacement animation: "+ index);
				}
			}
			
			if(clip == null)
			{
				Log.error(this, "Cannot find any character animations to use, replacing with rectangle. ");
				
				/*public static const ANI_ARRAY_IDLE:String = 'aniArrayIdle';		blue
				public static const ANI_ARRAY_WALK:String = 'aniArrayWalk';			yellow
				public static const ANI_ARRAY_ATTACK:String = 'aniArrayAttack';		green
				public static const ANI_ARRAY_HIT:String = 'aniArrayHit';			red
				public static const ANI_ARRAY_DODGE:String = 'aniArrayDodge';		pink
				public static const ANI_ARRAY_DEATH:String = 'aniArrayDeath';		black	*/
				
				clip = new MovieClip();
				clip.name = 'placeholder';
					
				if (arr == _aniArrs[ANI_ARRAY_IDLE]) 	
					clip.graphics.beginFill(0x4444FF, 0.8);
				if (arr == _aniArrs[ANI_ARRAY_WALK]) 	
					clip.graphics.beginFill(0xFFFF44, 0.8);
				if (arr == _aniArrs[ANI_ARRAY_ATTACK]) 	
					clip.graphics.beginFill(0x44FF44, 0.8);
				if (arr == _aniArrs[ANI_ARRAY_HIT]) 	
					clip.graphics.beginFill(0xFF4444, 0.8);
				if (arr == _aniArrs[ANI_ARRAY_DODGE])	
					clip.graphics.beginFill(0xFF44FF, 0.8);
				if (arr == _aniArrs[ANI_ARRAY_DEATH])	
					clip.graphics.beginFill(0x000000, 0.8);
				
				clip.graphics.drawRoundRect(-30,-70,60,100,5,5);
				clip.graphics.endFill();
			}
			
			clip.stop();
			arr[index] = clip;
			return clip;
		}	
		
		public function changeSprite(inX:int, inY:int, aniArrConst:String, playMC:Boolean = false):void
		{
			var newWalk:Boolean = (_aniArrCurrent != IsoCharacter.ANI_ARRAY_WALK && aniArrConst == IsoCharacter.ANI_ARRAY_WALK);
			_aniArrCurrent = aniArrConst;
			var aniArr:Array = _aniArrs[_aniArrCurrent];
			var newMC:MovieClip;
			_dX = inX;
			_dY = inY;
			
			newMC = getScaledMC(aniArr);
			
			if (newMC && newMC != _liveMC)
			{
				if (_liveMC)
				{
					_liveMC.stop();
					removeAsset(_liveMC);
				}
				
				_liveMC = newMC;
				
				_actions = new IsoFrameActions(_liveMC);
				
//				FrameLabelSound.cacheSoundGroup(_actions.getAllSoundFrameActions());
				
				// add character asset to the asset layer
				// you should never see addChild or removeChild in any 
				// sublclasses of IsoBase (IsoTile is temp exception)
				addAsset(_liveMC);
				
				if (aniArrConst != IsoCharacter.ANI_ARRAY_WALK)
					_frameCount = 0;
				else if (newWalk)
					_frameCount = 7;
				
				if (playMC)
					_liveMC.play();
				else
					_liveMC.stop();
			}
			
			onAssetUpdated();
		}
		
		public function playerFrameSounds():void
		{
			var actions:Array = (!_actions) ? [] : _actions.getFrameActionsOfType(_liveMC.currentFrame, FrameAction.TYPE_SFX);
			
			for each (var action:FrameAction in actions)
			{
				if (action) {
					var randSounds:Array = (action.asset) ? action.asset.split(',') : [];
					if (randSounds.length) {
						var randIndex:int = Math.floor((Math.random() * randSounds.length));
						var randString:String = randSounds[randIndex];
						FrameLabelSound.playSound(randString);
						//trace(randIndex + " / " + randSounds.length);
						//trace(action.asset);
					}
				}
			}	
		}	
		
		public function getHitActions():Array
		{
			if (_actions){
				return _actions.getFrameActionsOfType(_liveMC.currentFrame, FrameAction.TYPE_HIT);				
			}
			return [];
		}	
		
		public function getShakeActions():Array
		{
			if (_actions){
				return _actions.getFrameActionsOfType(_liveMC.currentFrame, FrameAction.TYPE_SHAKE);
			}
			return [];
		}	
		
		public function getLaunchActions():Array
		{
			if (_actions){
				return _actions.getFrameActionsOfType(_liveMC.currentFrame, FrameAction.TYPE_LAUNCH);
			}
			return [];
		}	
		
		public function getHitCount():int
		{
			if (_actions){
				return _actions.getAllFrameActionsOfType(FrameAction.TYPE_HIT).length;
			}
			return 0;
		}	
		
		public function onAssetUpdated():void
		{
			// override
		}	
		
		public function mover():MoverCharacter
		{
			trace('override this function');
			return null;
		}
		
		public function updateFrame(isoDist:Number):Boolean
		{
			if (!_liveMC) return true;
			
			var frameTotal:int = _liveMC.totalFrames;
			var returnVal:Boolean;
			if (!isNaN(isoDist)) _frameCount += isoDist;
			
			// (_characterMover as Mover).speed/1.8 *
			if (_frameCount % frameTotal < _frameCount) {
				returnVal = true;
			}
			
			_frameCount = _frameCount % frameTotal;
			
			_liveMC.gotoAndStop(Math.round(_frameCount + 1));
			
			if (Math.round(sortY) != _wholeSortY)
			{
				try{
					// TODO: TJ - this is still getting called after removed from stage, find out why its not getting cleaned up.
					_wholeSortY = sortY;
					(parent.parent as IsoMap).sortBubble(this);
				} catch(e:Error){
					//Log.error(this, "updateFrame() is running with no _liveMC");
				}	
				
			}
			updateOverlayPosition();
			
			return returnVal;
		}
		
		public function updateOverlayPosition():void
		{
			// override
		}
		
		protected override function redraw():void
		{
			super.redraw();
		}
		
		protected function addAnimation(asset:*, aniArrConst:String):void
		{
			
			if(asset)
			{
				var mc:MovieClip = asset as MovieClip;
				mc.stop(); 
				
				FrameLabelSound.cacheSoundsFromClip(asset);
				
				(_aniArrs[aniArrConst] as Array).push(mc);
			}else{
				Log.error(this, "Cannot create clip animation for "+ aniArrConst);
				
			}
			
		}
		
		public function getMC():MovieClip
		{
			return _liveMC;
		}
		
		public function moveStart():void
		{
			// override 
		}
		
		public function moveStop():void
		{
			// override 
		}
		
		public function rewindAnimation():void
		{
			_frameCount = 0;
			_actions && _actions.reset();
		}
		
		public function get assetIdleHeight():Number
		{
			try{
				var clip:MovieClip;
				if (_aniArrs[IsoCharacter.ANI_ARRAY_IDLE] && _aniArrs[IsoCharacter.ANI_ARRAY_IDLE].length > 0)
				{
					clip = MovieClip(_aniArrs[IsoCharacter.ANI_ARRAY_IDLE][_aniArrs[IsoCharacter.ANI_ARRAY_IDLE].length - 1]);
				}
				return Math.abs(clip.getBounds(clip).y);
			} catch(e:Error){
				//Log.error(this, "Cannot find idle animation");
			}	
			
			return 100;
		}
		
		override public function get mapOverlayPostion():Point
		{
			return new Point(x, y - assetIdleHeight - OVERLAY_PADDING);
		}
	}
}
