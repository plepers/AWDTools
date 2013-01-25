package awd {

	import flash.utils.Endian;
	import flash.utils.ByteArray;
	import awd.misc.Matrix3D;
	import awd.NamedAsset;

	/**
	 * @author Pierre Lepers
	 * awd.Geometry
	 */
	public class Geometry extends NamedAsset {

		public var num_subs : uint;
		
		// ???
		public var bsm : Matrix3D;
		
		
		public var subs : Vector.<SubGeometry>;
		

		public function Geometry() {
			subs = new Vector.<SubGeometry>();
		}

		override public function updateBlock() : void {
			super.updateBlock();
			var bytes : ByteArray = block.bounds.bytes;
			
			// need upsate?
			
			var mlengths : Vector.<uint> = new Vector.<uint>( subs.length, true );
			var needUpdate : Boolean = false;
			var b : BytesBounds;
			var sub : SubGeometry;
			for (var i : int = 0; i < subs.length; i++) {
				sub = subs[i];
				b = sub.indicesBounds;
				if( b ) {
					mlengths[i] += b.length;
					if( b.bytes != bytes ) {
						needUpdate = true;
					}
				}
				b = sub.verticesBounds;
				if( b ) {
					mlengths[i] += b.length;
					if( b.bytes != bytes ) {
						needUpdate = true;
					}
				}
				b = sub.colorsBounds;
				if( b ) {
					mlengths[i] += b.length;
					if( b.bytes != bytes ) {
						needUpdate = true;
					}
				}
				b = sub.normalsBounds;
				if( b ) {
					mlengths[i] += b.length;
					if( b.bytes != bytes ) {
						needUpdate = true;
					}
				}
				b = sub.uvsBounds;
				if( b ) {
					mlengths[i] += b.length;
					if( b.bytes != bytes ) {
						needUpdate = true;
					}
				}
				
				if(  sub.compositeData ) {
					for ( var j : int = 0; j < sub.compositeData.groups.length ; j++) {
						b = sub.compositeData.groups[j];
						mlengths[i] += b.length;
						if( b.bytes != bytes ) {
							needUpdate = true;
						}
					}
				}
			}
			
			if( ! needUpdate ) 
				return;
			
			
			bytes = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			block.bounds = new BytesBounds(0, 0, bytes);
			// parentId
			
			writeName(bytes);
			
			bytes.writeShort(subs.length);
			
			bytes.writeUnsignedInt(0); // no props
			
			for ( i = 0; i < subs.length; i++) {
				
				bytes.writeUnsignedInt(mlengths[i] + 4); // + props
				bytes.writeUnsignedInt(0); // no props
				
				sub = subs[i];
				
				b = sub.indicesBounds;
				if( b ) {
					bytes.writeByte( 2 );
					bytes.writeUnsignedInt( b.length );
					bytes.writeBytes( b.bytes, b.position,b.length );
				}
				
				b = sub.verticesBounds;
				if( b ) {
					bytes.writeByte( 1 );
					bytes.writeUnsignedInt( b.length );
					bytes.writeBytes( b.bytes, b.position,b.length );
				}
				b = sub.colorsBounds;
				if( b ) {
					bytes.writeByte( 9 );
					bytes.writeUnsignedInt( b.length );
					bytes.writeBytes( b.bytes, b.position,b.length );
				}
				b = sub.normalsBounds;
				if( b ) {
					bytes.writeByte( 4 );
					bytes.writeUnsignedInt( b.length );
					bytes.writeBytes( b.bytes, b.position,b.length );
				}
				b = sub.uvsBounds;
				if( b ) {
					bytes.writeByte( 3 );
					bytes.writeUnsignedInt( b.length );
					bytes.writeBytes( b.bytes, b.position,b.length );
				}
				
				if(  sub.compositeData ) {
					var clen : uint = 0;
					var glen : int = sub.compositeData.groups.length;
					for ( j = 0; j < glen ; j++) {
						b = sub.compositeData.groups[j];
						clen += b.length + 4;
					}


					bytes.writeByte( 8 );
					bytes.writeUnsignedInt( clen );

					for ( j = 0; j < glen ; j++) {
						b = sub.compositeData.groups[j];
						bytes.writeShort( sub.compositeData.groupIds[j] );
						bytes.writeShort( b.length>>1 );
						bytes.writeBytes( b.bytes, b.position,b.length );
					}
				}
				
				
				bytes.writeUnsignedInt(0); // no UserAttributes
			}
			
			bytes.writeUnsignedInt(0); // no UserAttributes
			
			block.bounds.length = bytes.length;
			
		}


	}
}
