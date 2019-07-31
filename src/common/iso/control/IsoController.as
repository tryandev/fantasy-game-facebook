package common.iso.control
{
	import by.blooddy.crypto.Base64;
	import by.blooddy.crypto.image.JPEGEncoder;
	
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.media.sound.RakaSoundManager;
	
	import common.iso.control.audio.FrameLabelSound;
	import common.iso.model.IsoModel;
	import common.iso.view.containers.IsoWorld;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.test.debug.FPS;
	import common.test.debug.KeyboardFull;
	import common.util.StageRef;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	

	public class IsoController
	{
		
		//--------
		private static const FPS_FOCUS:int = 30;
		private static const FPS_BLUR:int = 30;
		
		
		private static var _instance:IsoController;
		private var _isInitialized:Boolean;
		private var _view:Sprite;
		private var _isoWorld:IsoWorld;
		private var _avatar:IsoAvatar;

		private var _timeOfLastSound:int;
		private var _lastSoundVariance:int;
		
		public function IsoController(se:SE)
		{
			se;
		}

		public static function get gi():IsoController
		{
			return _instance || (_instance = new IsoController(new SE()));
		}

		public function initialize(view:Sprite = null):void
		{
			if (_isInitialized)
				return;

			_isInitialized = true;

			_view = view || StageRef.stage.addChild(new Sprite()) as Sprite;

			if(GameObjectManager.player.isAdmin)
			{
				StageRef.stage.addChild(new FPS());
			}
			
			// populate
			var gridWidth:int = IsoModel.gi.gridWidth;
			var gridLength:int = IsoModel.gi.gridHeight;
			_isoWorld = new IsoWorld();
			_view.addChild(_isoWorld);

			// handle keyboard events
			StageRef.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardHandler, false, 0, true);
			
			// handle focus events
			StageRef.stage.addEventListener(Event.ACTIVATE, focusHandler);
			StageRef.stage.addEventListener(Event.DEACTIVATE, focusHandler);
			
			// handle mouse wheel events
			ExternalInterface.addCallback("onWheelScroll", wheelScrollHandler);
			ExternalInterface.addCallback("getScreenShot", getScreenShot);
			
		}
		
		private function focusHandler(e:Event = null):void 
		{
			if (e.type == Event.DEACTIVATE) 
			{
				StageRef.stage.frameRate = FPS_BLUR;
			}
			else
			{
				StageRef.stage.frameRate = FPS_FOCUS;
			}
		}
		
		public function resumeMouseMode(pauser:Object):void
		{
			if(isoWorld && isoWorld.isoMap)
			{
				isoWorld.isoMap.resumeMouseMode(pauser);
			}
		}
		
		public function pauseMouseMode(pauser:Object, resetMouseMode:Boolean = true):void
		{
			if(isoWorld && isoWorld.isoMap)
			{
				isoWorld.isoMap.pauseMouseMode(pauser,resetMouseMode);
			}
		}
		
		public function wheelScrollHandler(delta:Number):void {
			if (delta > 0) {
				_isoWorld.zoomIn();
			}else{
				_isoWorld.zoomOut();
			}
		}
		
		public function getScreenShot():String {
			var scale:Number = 0.25;
			var blur:Number = 10;
			var quality:Number = 80;
			
			var rect:Rectangle = new Rectangle(0, 0, StageRef.stage.stageWidth*scale, StageRef.stage.stageHeight*scale);
			var pt:Point = new Point();
			var mx:Matrix = new Matrix(scale, 0.0, 0.0, scale, 0, 0);
			var mx2:Matrix = new Matrix(1/scale, 0.0, 0.0, 1/scale, 0, 0);
			var bd:BitmapData = new BitmapData(StageRef.stage.stageWidth*scale, StageRef.stage.stageHeight*scale);
			bd.draw(StageRef.stage, mx);
			bd.applyFilter(bd, rect, pt, new BlurFilter(blur * scale, blur * scale, 3));
			/*var bd2:BitmapData = new BitmapData(StageRef.stage.stageWidth, StageRef.stage.stageHeight);
			bd2.draw(bd, mx2);*/
			var imgBytes:ByteArray = JPEGEncoder.encode(bd, quality);
			//var imgBytes:ByteArray = PNGEncoder.encode(bd);
			var imgString:String = Base64.encode(imgBytes);
			var result:String = 'data:image/jpg;base64,' +  imgString;
			return result;
		}
		
		public function playSoundFX(sound:String):void
		{
			if (isReadyToPlaySound())
			{
				RakaSoundManager.getInstance().playSoundFX(sound);
				playedSound();
			}
		}
		
		public function getSoundFX(sound:String):void
		{
			
		}
		
		public function playStreamingSound(sound:String):void
		{
			if (isReadyToPlaySound())
			{
				FrameLabelSound.playSound(sound);
				playedSound();
			}
		}
		
		private function playedSound():void
		{
			_timeOfLastSound = getTimer();
			_lastSoundVariance = (Math.random() - 0.5) * AppConfig.game.getNumberValue(GameConfigEnum.BATTLE_SOUND_INTERVAL_VARIANCE);
		}
		
		private function isReadyToPlaySound():Boolean
		{
			return ((getTimer() - _timeOfLastSound) + _lastSoundVariance) > AppConfig.game.getNumberValue(GameConfigEnum.MIN_INTERVAL_BETWEEN_BATTLE_SOUNDS);
		}

		public function get isoWorld():IsoWorld
		{
			return _isoWorld;
		}

		private function keyboardHandler(e:KeyboardEvent):void
		{
			if (!GameObjectManager.player.isAdmin) return;
			
			if (e.keyCode == KeyboardFull.G)
			{
				System.gc();
			}
			
			if (e.keyCode == KeyboardFull.B)
			{
				_isoWorld.isoMap.drawBackground();
			}
			
			if (e.keyCode == KeyboardFull.H)
			{
				//_isoWorld.isoMap.debugShowHitAreas();
			}
		}
	}
}

internal class SE
{
}
