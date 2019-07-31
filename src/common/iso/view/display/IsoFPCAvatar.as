package common.iso.view.display 
{
	import com.greensock.TweenLite;
	import com.raka.commands.interfaces.ICommand;
	import com.raka.crimetown.control.hud.HudController;
	import com.raka.crimetown.model.game.PlayerOutfit;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.proxy.IResponder;
	
	import common.iso.control.IsoController;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverHomeAndFriendTownNPC;
	import common.iso.view.events.IsoAvatarEvent;
	import common.ui.view.overlay.FPCOverlay;
	import common.ui.view.overlay.NPCFriendName;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class IsoFPCAvatar extends IsoAvatar
	{		
		public static var IDLE_TYPES:Array = 	["Avatar_Idle_S",	"Avatar_Idle_SE",	"Avatar_Idle_E",	"Avatar_Idle_NE", 	"Avatar_Idle_N"];
		public static var WALK_TYPES:Array = 	["Avatar_Walk_S",	"Avatar_Walk_SE",	"Avatar_Walk_E",	"Avatar_Walk_NE", 	"Avatar_Walk_N"];
		public static var HIT_TYPES:Array = 	["Avatar_Hit_E",	"Avatar_Hit_E",		"Avatar_Hit_E",		"Avatar_Hit_E", 	"Avatar_Hit_E"];
		
		private const NAME_PADDING:int = 55;
		
		private var _friendOverlay:FPCOverlay;
		private var _nameLabel:Sprite;
		private var _label:NPCFriendName;
		
		public function IsoFPCAvatar(outfit:PlayerOutfit, showArmor:Boolean = true)
		{
			super(outfit, showArmor);
			
			_label = new NPCFriendName();	
			addUI(_label);
			
			_friendOverlay = new FPCOverlay();
			_friendOverlay.show();
			
			_populatedBodyPart = new Dictionary(true);
			
			this.alpha = 0;
		}
		
		public function setType(value:String):void
		{
			_friendOverlay.type = value;
		}
		
		public function setName(name:String):void
		{
			_label.setName(name);
			updateNamePosition();
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
//				_overlay.setMapPosition(mapOverlayPostion);
//				_friendOverlay.setMapPosition(new Point(x, y + (0.5-IsoController.gi.isoWorld.scale)*100));			
				_friendOverlay.setMapPosition(mapOverlayPostion);			
			}
		}
		
		private function updateNamePosition():void
		{
			if(_label)
			{
				_label.x = -_label.width/2;
				_label.y = -assetIdleHeight - NAME_PADDING;
			}
		}	
		
		override public function get mapOverlayPostion():Point
		{
			return new Point(x, y + _label.y/5 - (IsoController.gi.isoWorld.scale * 50) );	
		}
		
		override public function initialize( loadAssets:Boolean = true, responder:IResponder = null ):void
		{
			_showBestArmor = false;
			_characterMover.speed = AppConfig.game.getNumberValue(GameConfigEnum.AVATAR_RUN_SPEED)/4 * scaleX;
			//if(scaleX < 1) _characterMover.speedRatio *= (1-scaleX)*3.5; // unecessary
			
			super.initialize(false);
			
			// TODO - aray - overrides really don't need to be here at soft launch, so check IsoAvatar again and update as necessary.
			// currently neccessary because "walk" is being overridden by run in iso avatar for some reason
			// overrides
			var female:Boolean = (_outfit.gender == 'female');
			_urlAssetWalk =		this.getAssetUrl((female ? 'Female_':'') + 'Avatar', 'Walk');
			
			loadRequiredAssets();
		}
		
		public override function dispose():void
		{
			if(_friendOverlay) _friendOverlay.dispose();
			if(_label) _label.dispose();
			
			super.dispose();
		}
			
		override protected function onReadyAsset(c:ICommand):void
		{
			c.dispose();
			
			_assetsLoaded++;
			if (_assetsLoaded < _assetsTotal) {
				return;
			}
			
			addAnimations(IDLE_TYPES,		IsoCharacter.ANI_ARRAY_IDLE,	_urlAssetIdle);
			//if (!_profileView) {
				addAnimations(WALK_TYPES,		IsoCharacter.ANI_ARRAY_WALK,	_urlAssetWalk);
				addAnimations(HIT_TYPES,		IsoCharacter.ANI_ARRAY_HIT,		_urlAssetHit);
				//addAnimations(DODGE_TYPES,		IsoCharacter.ANI_ARRAY_DODGE,	_urlAssetDodge);
			//}
			
			updateNamePosition();
			
			changeSprite(1, 1, ANI_ARRAY_IDLE, false);
			_characterMover.stop();
			_assetsReady = true;
			this.addShadow()
			dispatchEvent(new IsoAvatarEvent(IsoAvatarEvent.ASSET_READY));
			
			_characterMover.start();
			
			if(_nameLabel)
			{
				_nameLabel.x = -_nameLabel.width / 2;
				_nameLabel.y = -(assetIdleHeight) - NAME_PADDING;
			}
			
			TweenLite.to( this, 1, {alpha: 1});
		}
						
		public override function mover():MoverCharacter {
			return _characterMover;
		}
		
		// ISOSTATE OVERRIDES
		// -----------------------------------------------------------------//
		
		override public function mouseOver():void
		{
			showHighlight(true);
			_friendOverlay.isoMouseOver();
			MoverHomeAndFriendTownNPC(_characterMover).togglePause(false);
		}
		
		override public function mouseOut():void
		{
			showHighlight(false);
			_friendOverlay.isoMouseOut();
			MoverHomeAndFriendTownNPC(_characterMover).togglePause(true);
		}
		
		override public function mouseUp():void
		{
			/* Need to send the FB ID of the friend who is clicked */
			if(_friendOverlay.type == "facebook_friend") 
			{
				HudController.getInstance().showInviteTab();
			}
			else 
			{
				HudController.getInstance().openGiftsPopup();
			}
		}
	}
}
