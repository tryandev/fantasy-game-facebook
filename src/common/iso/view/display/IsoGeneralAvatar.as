package common.iso.view.display 
{
	import com.raka.commands.interfaces.ICommand;
	import com.raka.crimetown.control.hud.HudController;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.Item;
	import com.raka.crimetown.model.game.PlayerOutfit;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.iso.map.MapConfig;
	
	import common.iso.control.IsoController;
	import common.iso.control.ai.MoverAvatar;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverHomeAndFriendTownNPC;
	import common.iso.control.cmd.IsoCommandLoadAsset;
	import common.iso.control.load.FactoryKeyArmorBest;
	import common.iso.model.IsoModel;
	import common.iso.view.events.IsoAvatarEvent;
	import common.ui.view.overlay.FPCOverlay;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	// TODO - aray - this class (IsoAvatar) is core to much of what people are working on, so I duped it with the intention
	// of replacing IsoAvatar with this... I tried editing IsoAvatar directly and it broke a few unrelated features...
	
	public class IsoGeneralAvatar extends IsoCharacter
	{
		private var _assetsLoaded:int;
		private var _assetsTotal:int;
		private var _requiredAssets:Array;
		private var _urlAssetIdle:String;
		private var _urlAssetWalk:String;
		private var _urlAssetHit:String;
		//private var _urlAssetWalkSlow:String;
		//private var _urlAssetAttack:String;
		
		private var _urlAssetBody:String;
		private var _urlAssetTop:String;
		private var _urlAssetBottom:String;
		private var _urlAssetHair:String;
		private var _urlAssetFacialHair:String;
		private var _urlAssetGlasses:String;
		private var _urlAssetHat:String;
		private var _urlAssetMask:String;
		
		private var _commands:Array;
		
		private var _showArmor:Boolean;
		private var _assetsReady:Boolean;
		private var _nameLabel:Sprite;
		
		public static var IDLE_TYPES:Array = 	["Avatar_Idle_S",	"Avatar_Idle_SE",	"Avatar_Idle_E",	"Avatar_Idle_NE", 	"Avatar_Idle_N"];
		public static var WALK_TYPES:Array = 	["Avatar_Walk_S",	"Avatar_Walk_SE",	"Avatar_Walk_E",		"Avatar_Walk_NE", 	"Avatar_Walk_N"];
		public static var HIT_TYPES:Array = 	["Avatar_Hit_E",	"Avatar_Hit_E",		"Avatar_Hit_E",		"Avatar_Hit_E", 	"Avatar_Hit_E"];
		
	
		private var _outfit:PlayerOutfit;
		
		private var _friendOverlay:FPCOverlay;
		private var _populatedBodyPart:Dictionary;
		
		public var isFighting:Boolean;
		
		public function IsoGeneralAvatar(outfit:PlayerOutfit, showArmor:Boolean = true)
		{
			super();
			_outfit = outfit;
			_showArmor = showArmor;
			
			_friendOverlay = new FPCOverlay();
			_friendOverlay.show();
			
			_populatedBodyPart = new Dictionary(true);
		}
		
		public function setType(value:String):void
		{
			_friendOverlay.type = value;
		}
		public function setName(name:String):void
		{
			_friendOverlay.setName(name);
		}
		public function setFacebookID(id:String):void
		{
			// kill image and load new one
			_friendOverlay.setPlatformID(id);
		}
		
		override public function updateOverlayPosition():void
		{
			if(_friendOverlay)
			{
				_friendOverlay.setMapPosition(new Point(x, y + (0.5-IsoController.gi.isoWorld.scale)*100));			
			}
		}
		
		public function initialize():void
		{
			_characterMover.speed = AppConfig.game.getNumberValue(GameConfigEnum.AVATAR_RUN_SPEED)/4 * scaleX;
			// if(scaleX < 1) _characterMover.speedRatio *= (1-scaleX)*3.5; // not required
			
			var playerArmor:Item;
			var keyHat:String;
			var keyTop:String;
			var keyBott:String;
			var keyMask:String;
			var female:Boolean = (_outfit.gender == 'female');
			
			if (_showArmor) {
				playerArmor = FactoryKeyArmorBest.get(GameObjectManager.player);
				if (playerArmor) {
					keyHat = 	playerArmor.armor_hat_outfit;
					keyTop =	playerArmor.armor_top_outfit;
					keyBott =	playerArmor.armor_bottom_outfit;
					keyMask = 	playerArmor.armor_mask_outfit;
					
					if (keyHat) keyHat = (female ? 'Female_':'') + keyHat;
					if (keyTop) keyTop = (female ? 'Female_':'') + keyTop;
					if (keyBott) keyBott = (female ? 'Female_':'') + keyBott;
					if (keyMask) keyMask = (female ? 'Female_':'') + keyMask;
				}
			}
			
			_urlAssetIdle =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Idle');
			_urlAssetWalk =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Walk');
			_urlAssetHit =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Hit');
			//_urlAssetWalkSlow =	this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Walk');
			//_urlAssetAttack =	this.getAssetUrl('Avatar', 'AttackSword1');
			
			_urlAssetHat =			this.getAssetUrl('Hat' 			, keyHat 	? keyHat:	_outfit.hat);		// Armor replaceable
			_urlAssetMask =			this.getAssetUrl('Mask' 		, keyMask	? keyMask:	_outfit.mask);		// Armor replaceable
			_urlAssetTop =			this.getAssetUrl('Top' 			, keyTop 	? keyTop:	_outfit.top);		// Armor replaceable
			_urlAssetBottom =		this.getAssetUrl('Bottom' 		, keyBott	? keyBott:	_outfit.bottom);	// Armor replaceable			
			_urlAssetBody =			this.getAssetUrl('Body' 		, _outfit.body);
			
			_urlAssetHair =			(_urlAssetHat || _urlAssetMask) ? null : this.getAssetUrl('Hair', _outfit.hair);
			_urlAssetFacialHair =	(_urlAssetMask) ? null : this.getAssetUrl('FacialHair', _outfit.facialHair);
			_urlAssetGlasses =		(_urlAssetMask) ? null : this.getAssetUrl('Glasses', _outfit.glasses);
			/*Log.info(this, 'IsAvatar body: ' 		+ _outfit.body);
			Log.info(this, 'IsAvatar top: ' 		+ _outfit.top);
			Log.info(this, 'IsAvatar bottom: ' 		+ _outfit.bottom);
			Log.info(this, 'IsAvatar hair: ' 		+ _outfit.hair);
			Log.info(this, 'IsAvatar facialHair: ' 	+ _outfit.facialHair);
			Log.info(this, 'IsAvatar glasses: ' 	+ _outfit.glasses);
			Log.info(this, 'IsAvatar hat: ' 		+ _outfit.hat);
			Log.info(this, 'IsAvatar mask: ' 		+ _outfit.mask);*/
			
			_requiredAssets = [];
			
			this.addRequiredAsset(_urlAssetIdle);
			this.addRequiredAsset(_urlAssetWalk);
			this.addRequiredAsset(_urlAssetHit);
			
			this.addRequiredAsset(_urlAssetBody);
			this.addRequiredAsset(_urlAssetTop);
			this.addRequiredAsset(_urlAssetBottom);
			this.addRequiredAsset(_urlAssetFacialHair);
			this.addRequiredAsset(_urlAssetGlasses);
			this.addRequiredAsset(_urlAssetHat);
			this.addRequiredAsset(_urlAssetMask);
			this.addRequiredAsset(_urlAssetHair);
			
			this.loadRequiredAsset();
		}
		
		public override function dispose():void
		{
			_outfit = null;
			var command:ICommand;
			for each (command in _commands)
			{
				command.dispose();
			}
			
			if(_friendOverlay) _friendOverlay.dispose();
			
			super.dispose();
		}
		
		public function replaceAsset(inAsset:MovieClip, aniArr:String, inIndex:int):void {
			if (_aniArrs[aniArr]) {
				_aniArrs[aniArr][inIndex] = inAsset;
			}else{
				throw new Error('_aniArrs[aniArr] is null?');
			}
		}
		
		private function getAssetUrl(inPrefix:String, inSuffix:String):String
		{
			if(!inPrefix || !inPrefix.length || !inSuffix || !inSuffix.length) return null;
			return MapConfig.getInstance().url("new_avatar_assets_url").replace(MapConfig.PLACEHOLDER, inPrefix + '_' + inSuffix);
		}
		
		private function addRequiredAsset(inUrl:String):void
		{
			if (!inUrl)
			{
				return;
			}
			
			_requiredAssets.push(inUrl);
			_assetsTotal++;
			//Log.info(this, '_assetsTotal++, ' + _assetsTotal);
		}
		
		private function loadRequiredAsset():void
		{
			_commands = new Array();
			for each (var url:String in _requiredAssets) {
				var command:IsoCommandLoadAsset = new IsoCommandLoadAsset(url, onReadyAsset, onFailureAsset);
				if (command) {
					_commands.push(command);	
					command.execute();	
				}
			}
		}
		
		private function onFailureAsset(c:ICommand):void {
			
		}
		
		private function onReadyAsset(c:ICommand):void
		{
			_assetsLoaded++;
			//Log.info(this, '_assetsLoaded++, ' + _assetsLoaded);
			if (_assetsLoaded < _assetsTotal) {
				return;
			}
			//Log.info(this, '_assetsLoaded Complete');
			
			addAnimations(IDLE_TYPES,		IsoCharacter.ANI_ARRAY_IDLE,	_urlAssetIdle);
			addAnimations(WALK_TYPES,		IsoCharacter.ANI_ARRAY_WALK,	_urlAssetWalk);
			addAnimations(HIT_TYPES,		IsoCharacter.ANI_ARRAY_HIT,		_urlAssetHit);
			//addAnimations(WALKSLOW_TYPES,	IsoCharacter.ANI_ARRAY_WALKSLOW,_urlAssetWalkSlow);
			
			trace(this + ' speed set to ' + _characterMover.speed);
			
			changeSprite(1, 1, ANI_ARRAY_IDLE, false);
			_characterMover.stop();
			dispatchEvent(new IsoAvatarEvent(IsoAvatarEvent.ASSET_READY));
			_assetsReady = true;
			
			_characterMover.start();
			
			if(_nameLabel)
			{
				_nameLabel.x = -_nameLabel.width / 2;
				_nameLabel.y = -(assetIdleHeight) - 20;
			}
			//addUI(_nameOverlay);
		}
		
		private function addAnimations(items:Array, animation:String, assetUrl:String):void {
			var item:String;
			
			for each (item in items) {
				//addAnimation(getClassInstance(((_outfit.gender == 'female') ? 'Female_':'') + item, assetUrl), animation);
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
		
		private function mcClear(inMC:DisplayObjectContainer):void {
			while(inMC.numChildren){
				inMC.removeChildAt(0);
			}
		}
		
		private function addPieceToBone(inTarget:Sprite, inDirection:String, inKeyUrl:String, inLinkage:String = ''):void {
			if (inKeyUrl == null || inKeyUrl.length < 1 ) return;
			var className:String = (inLinkage != '' ) ? inLinkage : inTarget.name;
			className += "_" + inDirection;
			var Klass:Class = IsoModel.gi.getCachedAsset(className, inKeyUrl);
			var instance:*;
			//if (inTarget.numChildren < 2) {
			if (Klass) {
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
			if (!_assetsReady) {
				trace(this + " - can't walk, assets not ready");
				return;
			}
			(_characterMover as MoverAvatar).walkNodeGoal(inAStarNodes);
		}
		
		// ISOSTATE OVERRIDES
		// -----------------------------------------------------------------//
		
		private var savedSpeed:Number = 0;
		
		override public function mouseOver():void
		{
			super.mouseOver();
			_friendOverlay.isoMouseOver();
			//_characterMover.stop();
			//_characterMover.stop();
			//MoverHomeAndFriendTownNPC(_characterMover).togglePause();
		}
		
		override public function mouseOut():void
		{
			super.mouseOut();
			_friendOverlay.isoMouseOut();
			//_characterMover.start();
			//_characterMover.start();
			//MoverHomeAndFriendTownNPC(_characterMover).togglePause();
		}
		
		override public function mouseUp():void
		{
			HudController.getInstance().openGiftsPopup();
		}
	}
}
