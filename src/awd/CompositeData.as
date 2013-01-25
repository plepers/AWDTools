package awd {

	import flash.utils.Dictionary;
	/**
	 * @author Pierre Lepers
	 * awd.CompositeData
	 */
	public class CompositeData {
		

		public function CompositeData() {
			dGroups = new Dictionary();
			groups = new Vector.<BytesBounds>();
			groupIds = new Vector.<uint>();
		}

		public function addGroup( bounds : BytesBounds, id : uint ) : void {
			groups.AS3::push( bounds );
			groupIds.AS3::push( id );
			dGroups[id] = bounds;
		}

		public function removeGroup( id : uint ) : void {
			var b : BytesBounds = dGroups[id];
			if( b == null ) return;
			
			groups.AS3::splice( groups.AS3::indexOf(b), 1);
			groupIds.AS3::splice(groupIds.AS3::indexOf( id ), 1);
			delete dGroups[id];
		}

		public function getGroup( id : uint ) : BytesBounds {
			return dGroups[id];
		}

		
		public var groupIds : Vector.<uint>;
		public var groups : Vector.<BytesBounds>;
		public var dGroups : Dictionary;

		public function extract() : void {
			for (var i : int = 0; i < groups.length; i++) {
				groups[i].extract();
			}
		}
		
	}
}
