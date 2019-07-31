package common.iso.control.audio
{
	import com.raka.iso.map.MapConfig;
	import com.raka.loader.RakaLoadSound;
	import com.raka.media.sound.IRakaSoundItem;
	import com.raka.media.sound.RakaSoundFXNotFoundError;
	import com.raka.media.sound.RakaSoundManager;
	
	import common.iso.control.IsoController;
	import common.iso.model.FrameAction;
	import common.iso.model.IsoModel;
	import common.iso.view.display.IsoFrameActions;
	
	import flash.display.MovieClip;

	public class FrameLabelSound {
		
		public static function playSound(soundKey:String):IRakaSoundItem 
		{
			return RakaSoundManager.getInstance().playStreamingSound(soundKey, getSoundURL(soundKey), RakaSoundManager.SOUND_FX_GROUP, false, 0);
		}
		
		public static function cacheSound(soundKey:String):IRakaSoundItem
		{
			if(!RakaSoundManager.getInstance().hasSoundFXCached(soundKey))
			{
//				trace("\t\t [:: CACHING SOUND ::]  ", soundKey);
				return FrameLabelSound.playSound(soundKey);
			}else{
//				trace("\t\t [:: ALREADY CACHING SOUND ::]  ", soundKey);
			}
			return null;
		}
		
		public static function cacheSoundsFromClip(clip:MovieClip):void
		{
			var actions:IsoFrameActions = new IsoFrameActions(clip);
			
			for each (var action:FrameAction in actions.getAllSoundFrameActions())
			{
				//FrameLabelSound.cacheSound(action.asset);
				if (action) {
					var allSounds:Array = (action.asset) ? action.asset.split(',') : [];
					while (allSounds && allSounds.length){
						var snd:String = allSounds.pop();
						if(snd.length<1)
							continue;
						FrameLabelSound.cacheSound(snd);
						//trace(Òsnd);
					}
				}
			}
		}
		
		public static function getSoundURL(soundKey:String):String
		{
			return IsoModel.gi.getSoundsUrl(soundKey);
		}	
	}
}