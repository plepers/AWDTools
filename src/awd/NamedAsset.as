package awd {
	import flash.utils.Endian;
	import flash.utils.ByteArray;
	/**
	 * @author Pierre Lepers
	 * awd.NamedAsset
	 */
	public class NamedAsset {
		
		public var extra : Object;
		
		public var name : String;
		
		public var block : AWDBlock;
		
		public function updateBlock() : void {
		}

		protected function writeName( bytes : ByteArray ) : void {
			
			var tmp : ByteArray = new ByteArray();
			tmp.endian = Endian.LITTLE_ENDIAN;
			tmp.writeUTFBytes( name );
			
			var len : uint = tmp.length;
			
			bytes.writeShort( len );
			bytes.writeBytes( tmp, 0, len );
			
			
		}
		
	}
}
