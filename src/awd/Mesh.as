package awd {

	import flash.utils.ByteArray;

	/**
	 * @author Pierre Lepers
	 * awd.Mesh
	 */
	public class Mesh extends Container {

		public var geom : Geometry;
		public var num_materials : uint;
		public var materials : Vector.<Material>;

		public function Mesh() {
			materials = new Vector.<Material>();
		}
		
		override public function updateBlock() : void {
			
			super.updateBlock();
			
			var bytes : ByteArray = block.bounds.bytes;
			
			// geom id
			bytes.writeUnsignedInt( geom.block.id );
			
			var offpos : uint = bytes.position - block.bounds.position;
			
			var oldMatLen : uint = bytes.readUnsignedShort();
			
			var s : uint = bytes.position + 4*oldMatLen;
			var l : uint = (block.bounds.position + block.bounds.length ) - s;
			
			if( oldMatLen != materials.length ) {
				
				
				var oldBytes : ByteArray = bytes;
				
				block.bounds.extract();
				block.bounds.bytes.position = offpos;
				bytes = block.bounds.bytes;
				bytes.writeShort(materials.length);
				
				for (var i : int = 0; i < materials.length; i++) {
					bytes.writeUnsignedInt( materials[i].block.id );
				}
				
				bytes.writeBytes( oldBytes, s, l )
//				bytes.writeUnsignedInt( 0 ); // Properties 
//				bytes.writeUnsignedInt( 0 ); // UserAttributes
				
				block.bounds.length = bytes.length;

			}
			
		}
		
	}
}
