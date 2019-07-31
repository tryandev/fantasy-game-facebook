package common.iso.control.audio
{
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.sound.CTSoundsForHometown;
	import com.raka.loader.IRakaBatchLoadItem;
	import com.raka.loader.IRakaLoadItem;
	import com.raka.loader.RakaBatchLoadItem;
	import com.raka.loader.RakaLoadPriorities;
	import com.raka.loader.RakaLoadService;
	import com.raka.loader.RakaLoadSound;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.utils.Config;
	import common.iso.model.IsoModel;

	public class SoundPreloadHometown {
		
		private static var _loaded:Boolean;
		
		public static function load():void {
			
			if (_loaded) {
				return;
			} else {
				_loaded = true;
			}
			
			var soundsToPreload:Vector.<String> = new Vector.<String>();
			soundsToPreload = soundsToPreload.concat(CTSoundsForHometown.HOMETOWN_SOUNDS_TO_PRELOAD);
			
			var id:String;
			var url:String;
			var loadItems:Array = [];
			
			for each (id in soundsToPreload) {
				url = IsoModel.gi.getSoundsUrl(id);
				var loadSound:IRakaLoadItem = new RakaLoadSound(url, RakaLoadPriorities.PRECACHE_PRIORITY);
				RakaSoundManager.getInstance().monitorPreload(loadSound);
				loadItems.push(loadSound);
			}
			
			if (loadItems.length > 0) {
				var batchPreload:IRakaBatchLoadItem = new RakaBatchLoadItem(loadItems);
				RakaLoadService.getInstance().load(batchPreload);
			}
		}
	}
}