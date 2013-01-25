package awd {
	import flash.utils.Endian;
	import flash.utils.ByteArray;
	/**
	 * @author Pierre Lepers
	 * awd.BytesBounds
	 */
	public class BytesBounds {

		public var position : uint;
		public var length : int;
		public var bytes : ByteArray;

		public function BytesBounds(position : uint, length : int, bytes : ByteArray ) {
			this.length = length;
			this.position = position;
			this.bytes = bytes;
		}

		public function extract() : void {
			var b : ByteArray = new ByteArray();
			b.endian = Endian.LITTLE_ENDIAN;
			b.writeBytes(bytes, position, length );
			bytes = b;
			position = 0;
		}

		public function clone() : BytesBounds {
			return new BytesBounds(position, length, bytes);
		}

		public function seekToEnd() : void {
			bytes.position = position+length;
		}

		public function seekToStart() : void {
			bytes.position = position;
		}

	}
}
