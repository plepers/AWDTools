package awd {

	import flash.utils.ByteArray;
	import awd.misc.Matrix3D;
	import awd.NamedAsset;

	/**
	 * @author Pierre Lepers
	 * awd.Container
	 */
	public class Container extends NamedAsset {

		public var parent : Container;
		public var mtx : Matrix3D;
		public var childs : Vector.<Container>;

		public function Container() {
			childs = new Vector.<Container>();
		}

		override public function updateBlock() : void {
			var bytes : ByteArray = block.bounds.bytes;
			// parentId
			bytes.position = block.bounds.position;
			
			var pid : uint = (parent != null)?parent.block.id : 0;
			bytes.writeUnsignedInt( pid );
			
			// matrix
			var raw : Vector.<Number> = mtx.raw;
			for (var i : int = 0; i < 16; i++) 
				bytes.writeFloat( raw[i] );
			
			// name
			writeName(bytes);
			
		}

		public function addChild(c : Container) : void {
			if( childs.AS3::indexOf(c) == -1)
				childs.AS3::push(c);
		}

	}
}
