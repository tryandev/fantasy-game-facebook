package common.iso.view.display 
{
	import com.raka.commands.interfaces.ICommand;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.Item;
	import com.raka.crimetown.model.game.Player;
	import com.raka.crimetown.model.game.PlayerItem;
	import com.raka.crimetown.model.game.PlayerOutfit;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.iso.map.MapConfig;
	import com.raka.proxy.IResponder;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.ai.AStarNode;
	import common.iso.control.ai.MoverAvatar;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.cmd.IsoCommandLoadAsset;
	import common.iso.control.cmd.a.AbstractIsoCommandLoad;
	import common.iso.control.load.FactoryKeyArmorBest;
	import common.iso.model.IsoModel;
	import common.iso.view.events.IsoAvatarEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class IsoAvatar extends IsoCharacter
	{
		public static var changePending:Boolean = false;
		public static var IDLE_TYPES:Array = 	["Avatar_Idle_S",	"Avatar_Idle_SE",	"Avatar_Idle_E",	"Avatar_Idle_NE", 	"Avatar_Idle_N"];
		public static var WALK_TYPES:Array = 	["Avatar_Run_S",	"Avatar_Run_SE",	"Avatar_Run_E",		"Avatar_Run_NE", 	"Avatar_Run_N"];
		public static var HIT_TYPES:Array = 	["Avatar_Hit_E",	"Avatar_Hit_E",		"Avatar_Hit_E",		"Avatar_Hit_E", 	"Avatar_Hit_E"];
		//public static var DODGE_TYPES:Array = 	["Avatar_Backflip_E",	"Avatar_Backflip_E",	"Avatar_Backflip_E",	"Avatar_Backflip_E", 	"Avatar_Backflip_E"];
		public static var DODGE_TYPES:Array = 	["Avatar_Dodge_E",	"Avatar_Dodge_E",	"Avatar_Dodge_E",	"Avatar_Dodge_E", 	"Avatar_Dodge_E"];
		
		protected var _assetsLoaded:int;
		protected var _assetsTotal:int;
		protected var _requiredAssets:Array;
		protected var _assetResponder:IResponder;
		
		protected var _urlAssetIdle:String;
		protected var _urlAssetWalk:String;
		protected var _urlAssetHit:String;
		protected var _urlAssetDodge:String;
		
		protected var _urlAssetBody:String;
		protected var _urlAssetTop:String;
		protected var _urlAssetBottom:String;
		protected var _urlAssetHair:String;
		protected var _urlAssetFacialHair:String;
		protected var _urlAssetGlasses:String;
		protected var _urlAssetHat:String;
		protected var _urlAssetMask:String;
		
		protected var _commands:Array;
		protected var _showBestArmor:Boolean;
		protected var _assetsReady:Boolean;
		protected var _outfit:PlayerOutfit;
		
		protected var _populatedBodyPart:Dictionary;
		private var _profileView:Boolean;
		
		public var isFighting:Boolean;
		
		public function IsoAvatar(outfit:PlayerOutfit, showBestArmor:Boolean = true, profileView:Boolean = false)
		{
			super();
			_outfit = outfit;
			_showBestArmor = showBestArmor;
			_populatedBodyPart = new Dictionary(true);
			_characterMover.speed = AppConfig.game.getNumberValue(GameConfigEnum.AVATAR_RUN_SPEED);
			_profileView = profileView;
		}
		
		public function initialize( loadAssets:Boolean = true, responder:IResponder = null ):void
		{
			var female:Boolean = (_outfit.gender == 'female');
			
			var hatCacheKey:String = _outfit.hat; 
			var maskCacheKey:String = _outfit.mask; 
			var topCacheKey:String = _outfit.top; 
			var bottomCacheKey:String = _outfit.bottom; 
			var bodyCacheKey:String = _outfit.body;
			var hairCacheKey:String = _outfit.hair;
			var glassesCacheKey:String = _outfit.glasses;
			var facialHairCacheKey:String = _outfit.facial_hair;
			
			if (_showBestArmor) {
				var playerArmor:Item = FactoryKeyArmorBest.get(GameObjectLookup.getPlayerById(_outfit.player_id));
				if (playerArmor) {
					hatCacheKey = 	playerArmor.armor_hat_outfit;
					topCacheKey =	playerArmor.armor_top_outfit;
					bottomCacheKey =	playerArmor.armor_bottom_outfit;
					maskCacheKey = 	playerArmor.armor_mask_outfit;
				}
			}
			
			if(female)
			{
				if(hatCacheKey != "" && hatCacheKey != null) hatCacheKey = 'Female_' + hatCacheKey;
				if(maskCacheKey != "" && maskCacheKey != null) maskCacheKey = 'Female_' + maskCacheKey;
				if(topCacheKey != "" && topCacheKey != null) topCacheKey = 'Female_' + topCacheKey;
				if(bottomCacheKey != "" && bottomCacheKey != null) bottomCacheKey = 'Female_' + bottomCacheKey; 
				
				// these already have Female_ in the db
				//if(bodyCacheKey != "") bodyCacheKey = 'Female_' + bodyCacheKey; 
				//if(hairCacheKey != "") hairCacheKey = 'Female_' + hairCacheKey; 
				//if(glassesCacheKey != "") glassesCacheKey = 'Female_' + glassesCacheKey; 
			}
			
			_urlAssetIdle =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Idle');
			_urlAssetWalk =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Run');
			_urlAssetHit =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Hit');
			_urlAssetDodge =	this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Dodge');		
			
			_urlAssetHat =			this.getAssetUrl('Hat' 			, hatCacheKey );	// Armor replaceable
			_urlAssetMask =			this.getAssetUrl('Mask' 		, maskCacheKey);	// Armor replaceable
			_urlAssetTop =			this.getAssetUrl('Top' 			, topCacheKey );	// Armor replaceable
			_urlAssetBottom =		this.getAssetUrl('Bottom' 		, bottomCacheKey );	// Armor replaceable			
			_urlAssetBody =			this.getAssetUrl('Body' 		, bodyCacheKey );
			
			_urlAssetHair =			((_urlAssetHat && _urlAssetHat.length) || (_urlAssetMask && _urlAssetMask.length)) ? null : this.getAssetUrl('Hair', hairCacheKey);
			_urlAssetFacialHair =	(_urlAssetMask && _urlAssetMask.length) ? null : this.getAssetUrl('FacialHair', facialHairCacheKey);
			_urlAssetGlasses =		(_urlAssetMask && _urlAssetMask.length) ? null : this.getAssetUrl('Glasses', glassesCacheKey);
			/*Log.info(this, 'IsAvatar body: ' 		+ playerOutfit.body);
			Log.info(this, 'IsAvatar top: ' 		+ playerOutfit.top);
			Log.info(this, 'IsAvatar bottom: ' 		+ playerOutfit.bottom);
			Log.info(this, 'IsAvatar hair: ' 		+ playerOutfit.hair);
			Log.info(this, 'IsAvatar facialHair: ' 	+ playerOutfit.facialHair);
			Log.info(this, 'IsAvatar glasses: ' 	+ playerOutfit.glasses);
			Log.info(this, 'IsAvatar hat: ' 		+ playerOutfit.hat);
			Log.info(this, 'IsAvatar mask: ' 		+ playerOutfit.mask);*/
			
			_requiredAssets = [];
						
			if(loadAssets) 
			{
				this.loadRequiredAssets(responder);
			}
		}
		
		public override function dispose():void
		{
			_outfit = null;
			var command:IsoCommandLoadAsset;
			while (_commands && _commands.length)
			{
				command = _commands.pop();
				command.dispose();
			}
			_commands = null;
			_populatedBodyPart = null;
			super.dispose();
		}
		
		public function get model():PlayerOutfit {
			return _outfit;
		}
		
		public function replaceAsset(inAsset:MovieClip, aniArr:String, inIndex:int):void 
		{
			if (_aniArrs[aniArr] && inAsset) 
			{
				_aniArrs[aniArr][inIndex] = inAsset;
			}
		}
		
		protected function getAssetUrl(inPrefix:String, inSuffix:String):String
		{
			if(!inPrefix || !inPrefix.length || !inSuffix || !inSuffix.length) return null;
			return MapConfig.getInstance().url("new_avatar_assets_url").replace(MapConfig.PLACEHOLDER, inPrefix + '_' + inSuffix);
		}
		
		protected function addRequiredAsset(inUrl:String):void
		{
			if (!inUrl)
			{
				return;
			}
			
			_requiredAssets.push(inUrl);
			_assetsTotal++;
			//Log.info(this, '_assetsTotal++, ' + _assetsTotal);
		}
		
		protected function loadRequiredAssets(responder:IResponder = null):void
		{
			_assetResponder = responder;
			
			_requiredAssets = [];
			this.addRequiredAsset(_urlAssetIdle);
			if (!_profileView) {
				this.addRequiredAsset(_urlAssetWalk);
				this.addRequiredAsset(_urlAssetHit);
				this.addRequiredAsset(_urlAssetDodge);
			}
			this.addRequiredAsset(_urlAssetBody);
			this.addRequiredAsset(_urlAssetTop);
			this.addRequiredAsset(_urlAssetBottom);
			this.addRequiredAsset(_urlAssetFacialHair);
			this.addRequiredAsset(_urlAssetGlasses);
			this.addRequiredAsset(_urlAssetHat);
			this.addRequiredAsset(_urlAssetMask);
			this.addRequiredAsset(_urlAssetHair);
			
			_commands = new Array();
			for each (var url:String in _requiredAssets) {
				var command:IsoCommandLoadAsset = new IsoCommandLoadAsset(url, onReadyAsset, onFailureAsset);
				if (command) {
					_commands.push(command);	
					command.execute();	
				}
			}
		}
		
		protected function onFailureAsset(c:ICommand):void {
			Log.warn(this, 'Load Failed or Cancelled: ' + IsoCommandLoadAsset(c).assetUrl);
			onReadyAsset(c);
			
			if (_assetResponder) 
			{
				_assetResponder.fault(this);
				_assetResponder = null;
			}
		}
		
		protected function onReadyAsset(c:ICommand):void
		{
			c.dispose();
			if (!_outfit) return;
			_assetsLoaded++;
			if (_assetsLoaded < _assetsTotal) {
				return;
			}
			
			if (_assetResponder) 
			{
				_assetResponder.result(this);
				_assetResponder = null;
			}
			
			addAnimations(IDLE_TYPES,		IsoCharacter.ANI_ARRAY_IDLE,	_urlAssetIdle);
			if (!_profileView) {
				addAnimations(WALK_TYPES,		IsoCharacter.ANI_ARRAY_WALK,	_urlAssetWalk);
				addAnimations(HIT_TYPES,		IsoCharacter.ANI_ARRAY_HIT,		_urlAssetHit);
				addAnimations(DODGE_TYPES,		IsoCharacter.ANI_ARRAY_DODGE,	_urlAssetDodge);
			}
			
			//updateNamePosition();
			
//			trace(this + ' speed set to ' + _characterMover.speed);
			
			changeSprite(1, 1, ANI_ARRAY_IDLE, false);
			_characterMover.stop();
			_assetsReady = true;
			this.addShadow();
			dispatchEvent(new IsoAvatarEvent(IsoAvatarEvent.ASSET_READY));
		}
		
		protected function addAnimations(items:Array, animation:String, assetUrl:String):void
		{
			if (!_outfit) return;
			
			var item:String;
			
			for each (item in items)
			{
				addAnimation(getClassInstance(((_outfit.gender == 'female') ? 'Female_':'') + item, assetUrl), animation);
			}
		}
		
		protected override function redraw():void
		{
			//this.scaleY = 0.8;
			super.redraw();
			return;
		}
		
		public override function mover():MoverCharacter {
			return _characterMover;
		}
		
		public function moverAvatar():MoverAvatar
		{
			return MoverAvatar(_characterMover);
		}

		public override function changeSprite(inX:int, inY:int, aniArrConst:String, playMC:Boolean = false):void
		{
			super.changeSprite(inX, inY, aniArrConst, playMC);
			var dirStr:String;
			
			if (inX ==  1 && inY ==  1) dirStr =  'S'; // S
			if (inX ==  1 && inY ==  0) dirStr = 'SE'; // SE
			if (inX ==  1 && inY == -1) dirStr =  'E'; // E
			if (inX ==  0 && inY == -1) dirStr = 'NE'; // NE
			if (inX == -1 && inY == -1) dirStr =  'N'; // N
			if (inX == -1 && inY ==  0) dirStr = 'NE'; // NW
			if (inX == -1 && inY ==  1) dirStr =  'E'; // W
			if (inX ==  0 && inY ==  1) dirStr = 'SE'; // SW
			
			var mc:Sprite;
			
			if (!_liveMC) return;
			
			for (var i:int = 0; i < _liveMC.numChildren; i++ ) {
				mc = _liveMC.getChildAt(i) as Sprite;
				if (!_populatedBodyPart[mc]) {
					
					// never populate this bodypart again
					_populatedBodyPart[mc] = true;
					
					switch (mc.name) {
						case 'Head':
							mcClear(mc);
							addPieceToBone(mc, dirStr, _urlAssetBody);
							
							addPieceToBone(mc, dirStr, _urlAssetHat, 		'Hat'); 
							addPieceToBone(mc, dirStr, _urlAssetHair, 		'Hair');
							
							addPieceToBone(mc, dirStr, _urlAssetMask, 		'Mask'); 
							addPieceToBone(mc, dirStr, _urlAssetFacialHair,	'FacialHair'); 
							addPieceToBone(mc, dirStr, _urlAssetGlasses, 	'Glasses'); 
							break;
						case 'Cape':			mcClear(mc);										  addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'Torso':			mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'LeftShoulder':	mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'LeftArm':			mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'LeftHand':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'RightShoulder':	mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'RightArm':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						case 'RightHand':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetTop); break;
						
						case 'Hip':				mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'LeftThigh':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'LeftLeg':			mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'LeftFoot':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'RightThigh':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'RightLeg':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;
						case 'RightFoot':		mcClear(mc);addPieceToBone(mc, dirStr, _urlAssetBody);addPieceToBone(mc, dirStr, _urlAssetBottom); break;

					}
				}
			}
		}
		
		protected function mcClear(inMC:DisplayObjectContainer):void {
			while(inMC.numChildren){
				inMC.removeChildAt(0);
			}
		}
		
		protected function addPieceToBone(inTarget:Sprite, inDirection:String, inKeyUrl:String, inLinkage:String = ''):void {
			if (inKeyUrl == null || inKeyUrl.length < 1 ) return;
			var className:String = (inLinkage != '' ) ? inLinkage : inTarget.name;
			className += "_" + inDirection;
			
			var instance:*;
			//if (inTarget.numChildren < 2) {
			if (IsoModel.gi.hasCachedAsset(className, inKeyUrl)) {
				var Klass:Class = IsoModel.gi.getCachedAsset(className, inKeyUrl);
				instance = new Klass();
			}else{
				instance = new Shape();
				instance.visible = false;
			}
			inTarget.addChild(instance);
			//}
		}
		
		public function walkNodeGoal(inAStarNodes:Array):void
		{
			if (_assetsReady) {
				moverAvatar().walkNodeGoal(inAStarNodes);
			}
		}
		
		override public function get mapOverlayPostion():Point
		{
			return new Point(x, y - assetIdleHeight);	
		}
		
		public function assetsReady():Boolean 
		{
			return _assetsReady;
		}
		
		protected function addShadow():void 
		{
			var shadowColor:int = 0x333520;
			var shadowAlpha:Number = 0.38;
			var shadowSize:int = 50;
			var g:Graphics = _assetDisplay.graphics;
			g.beginFill(shadowColor,shadowAlpha);
			g.drawEllipse(-shadowSize/2,-shadowSize/4 + IsoBase.GRID_PIXEL_SIZE/2, shadowSize,shadowSize/2);
			g.endFill()
		}
		
		override protected function showHighlight(show:Boolean):void 
		{
			if (this is IsoFPCAvatar) {
				super.showHighlight(show);
			}
		}
		
		public function doChangePending():void
		{
			if (!changePending) {
				return;
			}
			//trace('|||||||||||| avatar change: doChangePending NOW');
			changePending = false;
			IsoController.gi.isoWorld.isoMap.avatarReset();
		}
	}
}
