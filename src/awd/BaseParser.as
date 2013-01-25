


package awd {



	import awd.misc.Matrix3D;

	import flash.utils.ByteArray;
	import flash.utils.Endian;

	
	/**
	 * AWDParser provides a parser for the AWD data type.
	 */
	public class BaseParser 
	{
		protected var _byteData : ByteArray;
		protected var _startedParsing : Boolean;
		protected var _cur_block_id : uint;
		protected var _blocks : Vector.<AWDBlock>;
		protected var _idsMap : Vector.<uint>;
		
		protected var _version : Array;
		protected var _compression : uint;
		protected var _streaming : Boolean;
		
		protected var _optimized_for_accuracy : Boolean;
		
		protected var _texture_users : Object = {};
		
		protected var _parsed_header : Boolean;
		protected var _body : ByteArray;
		
		
		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
		
		
		public static const BLOCK_MESHDATA : uint = 1;
		public static const BLOCK_MATERIAL : uint = 81;
		public static const BLOCK_CONTAINER : uint = 22;
		public static const BLOCK_MESHINST : uint = 24;
		
		
		
		
		public static const AWD_FIELD_INT8 : uint = 1;
		public static const AWD_FIELD_INT16 : uint = 2;
		public static const AWD_FIELD_INT32 : uint = 3;
		public static const AWD_FIELD_UINT8 : uint = 4;
		public static const AWD_FIELD_UINT16 : uint = 5;
		public static const AWD_FIELD_UINT32 : uint = 6;
		public static const AWD_FIELD_FLOAT32 : uint = 7;
		public static const AWD_FIELD_FLOAT64 : uint = 8;
		
		public static const AWD_FIELD_BOOL : uint = 21;
		public static const AWD_FIELD_COLOR : uint = 22;
		public static const AWD_FIELD_BADDR : uint = 23;
		
		public static const AWD_FIELD_STRING : uint = 31;
		public static const AWD_FIELD_BYTEARRAY : uint = 32;
		
		public static const AWD_FIELD_VECTOR2x1 : uint = 41;
		public static const AWD_FIELD_VECTOR3x1 : uint = 42;
		public static const AWD_FIELD_VECTOR4x1 : uint = 43;
		public static const AWD_FIELD_MTX3x2 : uint = 44;
		public static const AWD_FIELD_MTX3x3 : uint = 45;
		public static const AWD_FIELD_MTX4x3 : uint = 46;
		public static const AWD_FIELD_MTX4x4 : uint = 47;
		
		
		/**
		 * Creates a new AWDParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 * @param extra The holder for extra contextual data that the parser might need.
		 */
		public function BaseParser( awd : ByteArray )
		{
			_byteData = awd;
			_blocks = new Vector.<AWDBlock>;
			_idsMap = new Vector.<uint>();
			_blocks[0] = new AWDBlock;
			_idsMap[0] = 0;
			
			_version = [];
			
			proceedParsing();
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.AS3::toLowerCase();
			return extension == "awd";
		}
		
	
		
		/**
		 * @inheritDoc
		 */
		protected function proceedParsing() : void
		{
			_byteData.endian = Endian.LITTLE_ENDIAN;
			
			//TODO: Create general-purpose parseBlockRef(requiredType) (return _blocks[addr] or throw error)
			
			// Parse header and decompress body
			parseHeader();
			switch (_compression) {
				case DEFLATE:
					_body = new ByteArray;
					_body.endian = Endian.LITTLE_ENDIAN;
					_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
					_body.uncompress();
					break;
				case LZMA:
					// TODO: Decompress LZMA into _body
					throw new Error( "awd.BaseParser - proceedParsing : LZMA" );
					break;
				case UNCOMPRESSED:
					_body = _byteData;
					break;
				
				// Define which methods to use when reading floating
				// point and integer numbers respectively. This way, 
				// the optimization test and ByteArray dot-lookup
				// won't have to be made every iteration in the loop.
//				read_float = _optimized_for_accuracy? _body.readDouble : _body.readFloat;
//				read_uint = _optimized_for_accuracy? _body.readUnsignedInt : _body.readUnsignedShort;
			}
			
			while (_body.bytesAvailable ) {
				parseNextBlock();
			}
			
		}
		
		protected function parseHeader() : void
		{
			var flags : uint;
			var body_len : Number;
			
			// Skip magic string and parse version
			_byteData.position = 3;
			_version[0] = _byteData.readUnsignedByte();
			_version[1] = _byteData.readUnsignedByte();
			
			// Parse bit flags and compression
			flags = _byteData.readUnsignedShort();
			_streaming 					= (flags & 0x1) == 0x1;
			_optimized_for_accuracy 	= (flags & 0x2) == 0x2;
			
			
			_compression = _byteData.readUnsignedByte();
			
			// Check file integrity
			body_len = _byteData.readUnsignedInt();
			
			if (!_streaming && body_len != _byteData.bytesAvailable) {
				throw ('AWD2 body length does not match header integrity field');
			}
		}
		
		protected function parseNextBlock() : void
		{
			
			var ns : uint, type : uint, len : uint;
			
			_cur_block_id = _body.readUnsignedInt();
			ns = _body.readUnsignedByte();
			type = _body.readUnsignedByte();
			len = _body.readUnsignedInt();

			var b : AWDBlock = _blocks[_cur_block_id] = new AWDBlock();
			b.id = _cur_block_id;
			b.type = type;
			b.bounds = new BytesBounds(_body.position, len, _body );
			
			var assetData : NamedAsset;
			
			switch (type) {
				case BLOCK_MESHDATA:
					assetData = parseMeshData(b);
					break;
				case BLOCK_CONTAINER:
					assetData = parseContainer(b);
					break;
				case BLOCK_MESHINST:
					assetData = parseMeshInstance(b);
					break;
				case BLOCK_MATERIAL:
					assetData = parseMaterial(b);
					break;
//				case 82:
//					assetData = parseTexture(len);
//					break;
				default:
					_body.position += len;
					break;
			}
			
//			trace( _cur_block_id, assetData )
			
			b.data = assetData;
			if( assetData ) assetData.block = b;
			
			
//			if( b.data ) trace( "awd.BaseParser - decompose -- ",  _cur_block_id, _blocks[_cur_block_id].data , _blocks[_cur_block_id].data.name);
			
		}
		
		
		protected function parseMaterial(block : AWDBlock) : NamedAsset
		{
			
			var mat : Material = new Material();
			
			var props : AWDProperties;
			var num_methods : uint;
			var methods_parsed : uint;
			
			mat.name = parseVarStr();
			mat.type = _body.readUnsignedByte();
			mat.num_methods = _body.readUnsignedByte();
			
			// Read material numerical properties
			// (1=color, 2=bitmap url, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			props = parseProperties({ 1:AWD_FIELD_INT32, 2:AWD_FIELD_BADDR, 
				11:AWD_FIELD_BOOL, 12:AWD_FIELD_FLOAT32, 13:AWD_FIELD_BOOL });
			
			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				var method_type : uint;
				
				method_type = _body.readUnsignedShort();
				parseProperties(null);
				parseUserAttributes();
			}
			
			
			mat.extra = parseUserAttributes();;
			mat.alphaThreshold = props.get(12, 0.0);
			mat.repeat = props.get(13, false);
			
			return mat;
			
		}
		
		
		protected function parseTexture(block : AWDBlock) : void
		{
			var name : String;
			var type : uint;
			var data_len : uint;
			
			name = parseVarStr();
			type = _body.readUnsignedByte();
			data_len = _body.readUnsignedInt();
			
			_texture_users[_cur_block_id.AS3::toString()] = [];
			
			// External
			if (type == 0) {
				var url : String;
				
				url = _body.readUTFBytes(data_len);
			}
			else {
//				var data : ByteArray;
////				var loader : Loader;
////				
//				data = new ByteArray();
				_body.position += data_len;
				//readBytes(data, 0, data_len);
				
			}
			
			parseProperties(null);
			parseUserAttributes();
			
		}
		
		
		
		protected function parseContainer(block : AWDBlock) : NamedAsset
		{
			var container : Container = new Container();
			
			var pid : uint = _body.readUnsignedInt();
			
			container.parent = _blocks[pid].data as Container;
			container.mtx = parseMatrix3D();
			container.name = parseVarStr();
			
			parseProperties(null);
			
			container.extra = parseUserAttributes();
			
			return container;
		}
		
		protected function parseMeshInstance(block : AWDBlock) : NamedAsset
		{
			var mesh : Mesh = new Mesh();
			
			var num_materials : uint;
			var materials_parsed : uint;
			
			var pid : uint = _body.readUnsignedInt();
			if( pid != 0 ) {
				mesh.parent = _blocks[pid].data as Container;
				(_blocks[pid].data as Container).addChild( mesh )
			}
			mesh.mtx = parseMatrix3D();
			mesh.name = parseVarStr();
			
//			trace( "awd.BaseParser - parseMeshInstance -- ",mesh.name );

			pid = _body.readUnsignedInt();
			var geom : Geometry = _blocks[pid].data as Geometry;
			mesh.geom = geom;

			
			num_materials = 
			mesh.num_materials = _body.readUnsignedShort();

			var materialIds : Vector.<Material> = mesh.materials;
			
			materials_parsed = 0;
			
			while (materials_parsed < num_materials) {
				pid = _body.readUnsignedInt();
				mesh.materials[materials_parsed] = _blocks[pid].data as Material;
				materials_parsed++;
			}
			
			
			if ( ( materialIds.length == 1 || geom.num_subs == 1) && (  materialIds.length & geom.num_subs )>0 ) {
				
			}
			else if( materialIds.length > 0 ){
				var i : uint;
				// Assign each sub-mesh in the mesh a material from the list. If more sub-meshes
				// than materials, repeat the last material for all remaining sub-meshes.
				for (i=0; i<geom.num_subs; i++) {
					//trace( "away3d.loaders.parsers.AWD2Parser - parseMeshInstance -- ",materials[Math.min(materials.length-1, i)] );
					geom.subs[i].material = materialIds[Math.min(materialIds.length-1, i)];
				}
			}
			
			// Ignore for now
			var props : AWDProperties = parseProperties( {2 : AWD_FIELD_BADDR} );
			
			mesh.extra = parseUserAttributes();
			
			return mesh;
			
		}
		
		
		protected function parseMeshData(block : AWDBlock) : NamedAsset
		{
			
			var geom : Geometry = new Geometry();
			
			var name : String;
			var num_subs : uint;
			var subs_parsed : uint;
			var props : AWDProperties;
			var bsm : Matrix3D;
			
			// Read name and sub count
			geom.name = parseVarStr();
			num_subs = 
			geom.num_subs = _body.readUnsignedShort();
			
			// Read optional properties
			props = parseProperties({ 1:AWD_FIELD_MTX4x4, 2 : AWD_FIELD_BADDR }); 
			
			var bsm_data : Array = props.get(1, null);
			if (bsm_data) {
				geom.bsm = new Matrix3D(Vector.<Number>(bsm_data));
			}
			
			var isGComposite : Boolean = false;

			
			
			// Loop through sub meshes
			subs_parsed = 0;
			while (subs_parsed < num_subs) {
				var isComposite : Boolean = false;
				var sm_len : uint, sm_end : uint;
				
				var subgeom : SubGeometry  =new SubGeometry();
				geom.subs.AS3::push( subgeom );
				
				sm_len = _body.readUnsignedInt();
				sm_end = _body.position + sm_len;
				
				// Ignore for now
				parseProperties(null);
				
//				trace( "awd.BaseParser - parseMeshData -- subs ", (subs_parsed+1), "/", num_subs );
				
				// Loop through data streams
				while (_body.position < sm_end) {
					var str_type : uint, str_len : uint, str_end : uint;
					
					str_type = _body.readUnsignedByte();
					str_len = _body.readUnsignedInt();
					str_end = _body.position + str_len;
					
//					trace( "	stream ",str_type );
					
					if (str_type == 1) {
						subgeom.verticesBounds = new BytesBounds( _body.position, str_len, _body );
					}
					else if (str_type == 2) {
						subgeom.indicesBounds = new BytesBounds( _body.position, str_len, _body );
					}
					else if (str_type == 3) {
						subgeom.uvsBounds = new BytesBounds( _body.position, str_len, _body );
					}
					else if (str_type == 4) {
						subgeom.normalsBounds = new BytesBounds( _body.position, str_len, _body );
					}
					else if (str_type == 9) {
						subgeom.colorsBounds = new BytesBounds( _body.position, str_len, _body );
					}
					else if (str_type == 6) {
						throw new Error( "away3d.loaders.parsers.FastAWD2Parser - parseMeshData : " );
					}
					else if (str_type == 7) {
						throw new Error( "away3d.loaders.parsers.FastAWD2Parser - parseMeshData : " );
					}
					else if (str_type == 8 ) {
						//subgeom.compositeBounds = new BytesBounds( _body.position, str_len, _body );

						var cdata : CompositeData = subgeom.compositeData = new CompositeData();

						isGComposite = 
						isComposite = true;
						
						var gid : uint;
						var glen : uint;
						
						var gbounds : BytesBounds;
						
						while (_body.position < str_end) {
							gid = _body.readUnsignedShort();
							glen = _body.readUnsignedShort();
							cdata.dGroups[gid] = gbounds = new BytesBounds(_body.position, glen << 1, _body );
							cdata.groups.AS3::push( gbounds );
							cdata.groupIds.AS3::push( gid );
							_body.position += glen<<1;
						}
						
					}
					
					
					_body.position = str_end;
				}
				if( subgeom.verticesBounds == null ) throw new Error( "awd.BaseParser - parseMeshData : " );
				
				// Ignore sub-mesh attributes for now
				parseUserAttributes();
				
				// If there were weights and joint indices defined, this
				// is a skinned mesh and needs to be built from skinned
				// sub-geometries, so copy data across.
				if( isComposite ) {
				}
				
				subs_parsed++;
			}
			
			
			
			parseUserAttributes();
			
			return geom;
			
		}
		
		
		protected function parseVarStr() : String
		{
			var len : uint = _body.readUnsignedShort();
			return _body.readUTFBytes(len);
		}
		
		
		// TODO: Improve this by having some sort of key=type dictionary
		protected function parseProperties(expected : Object) : AWDProperties
		{
			var list_end : uint;
			var list_len : uint;
			var props : AWDProperties;
			
			props = new AWDProperties();
			
			list_len = _body.readUnsignedInt();
			list_end = _body.position + list_len;
			
			if (expected) {
				while (_body.position < list_end) {
					var len : uint;
					var key : uint;
					var type : uint;
					
					key = _body.readUnsignedShort();
					len = _body.readUnsignedShort();
					if (expected.hasOwnProperty(key)) {
						type = expected[key];
						props.set(key, parseAttrValue(type, len));
					}
					else {
						_body.position += len;
					}
					
				}
			} else {
				_body.position = list_end;
			}
			
			return props;
		}
		
		protected function parseUserAttributes() : Object
		{
			var attributes : Object;
			var list_len : uint;
			
			list_len = _body.readUnsignedInt();
			if (list_len > 0) {
				var list_end : uint;
				
				attributes = {};
				
				list_end = _body.position + list_len;
				while (_body.position < list_end) {
					var ns_id : uint;
					var attr_key : String;
					var attr_type : uint;
					var attr_len : uint;
					var attr_val : *;
					
					// TODO: Properly tend to namespaces in attributes
					ns_id = _body.readUnsignedByte();
					attr_key = parseVarStr();
					attr_type = _body.readUnsignedByte();
					attr_len = _body.readUnsignedShort();
					
					switch (attr_type) {
						case AWD_FIELD_STRING:
							attr_val = _body.readUTFBytes(attr_len);
							break;
						default:
							attr_val = 'unimplemented attribute type '+attr_type;
							_body.position += attr_len;
							break;
					}
					
					attributes[attr_key] = attr_val;
				}
			}
			
			return attributes;
		}
		
		protected function parseAttrValue(type : uint, len : uint) : *
		{
			var elem_len : uint;
			var read_func : Function;
			
			switch (type) {
				case AWD_FIELD_INT8:
					elem_len = 1;
					read_func = _body.readByte;
					break;
				case AWD_FIELD_INT16:
					elem_len = 2;
					read_func = _body.readShort;
					break;
				case AWD_FIELD_INT32:
					elem_len = 4;
					read_func = _body.readInt;
					break;
				case AWD_FIELD_BOOL:
				case AWD_FIELD_UINT8:
					elem_len = 1;
					read_func = _body.readUnsignedByte;
					break;
				case AWD_FIELD_UINT16:
					elem_len = 2;
					read_func = _body.readUnsignedShort;
					break;
				case AWD_FIELD_UINT32:
				case AWD_FIELD_BADDR:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					break;
				case AWD_FIELD_FLOAT32:
					elem_len = 4;
					read_func = _body.readFloat;
					break;
				case AWD_FIELD_FLOAT64:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
				case AWD_FIELD_VECTOR2x1:
				case AWD_FIELD_VECTOR3x1:
				case AWD_FIELD_VECTOR4x1:
				case AWD_FIELD_MTX3x2:
				case AWD_FIELD_MTX3x3:
				case AWD_FIELD_MTX4x3:
				case AWD_FIELD_MTX4x4:
					elem_len = 8;
					read_func = _body.readDouble;
					break;
			}
			
			if (elem_len < len) {
				var list : Array;
				var num_read : uint;
				var num_elems : uint;
				
				list = [];
				num_read = 0;
				num_elems = len / elem_len;
				while (num_read < num_elems) {
					list.AS3::push(read_func());
					num_read++;
				}
				
				return list;
			}
			else {
				var val : *;
				
				val = read_func();
				return val;
			}
		}
		
//		protected function parseMatrix2D() : Matrix
//		{
//			var mtx : Matrix;
//			var mtx_raw : Vector.<Number> = parseMatrixRawData(6);
//			
//			mtx = new Matrix(mtx_raw[0], mtx_raw[1], mtx_raw[2], mtx_raw[3], mtx_raw[4], mtx_raw[5]);
//			return mtx;
//		}
		
		protected function parseMatrix3D() : Matrix3D
		{
			var mtx : Matrix3D = new Matrix3D(parseMatrixRawData());
			return mtx;
		}
		
		protected function parseMatrixRawData(len : uint = 16) : Vector.<Number>
		{
			var i : uint;
			var mtx_raw : Vector.<Number> = new Vector.<Number>;
			for (i=0; i<len; i++) {
				mtx_raw[i] = _body.readFloat();
			}
			
			return mtx_raw;
		}
		
		
		public function findByName(name : String) : NamedAsset {
			for (var j : int = 1; j < _blocks.length; j++) {
				if ( _blocks[j].data && _blocks[j].data.name == name )
					return _blocks[j].data;
			}
			return null;
		}

		public function findMesh(name : String) : Mesh {
			for (var j : int = 1; j < _blocks.length; j++) {
				if ( _blocks[j].data && _blocks[j].data as Mesh && _blocks[j].data.name == name )
					return _blocks[j].data as Mesh;
			}
			return null;
		}

		public function findContainer(name : String) : Container {
			for (var j : int = 1; j < _blocks.length; j++) {
				if ( _blocks[j].data && _blocks[j].data as Container && _blocks[j].data.name == name )
					return _blocks[j].data as Container;
			}
			return null;
		}

		public function getMesh( id : uint ) : Mesh {
			return _blocks[id].data as Mesh;
		}

		public function getGeom( id : uint ) : Geometry {
			return _blocks[id].data as Geometry;
		}

		public function getSceneTransform( c : Container ) : Matrix3D {
			var res : Matrix3D = new Matrix3D();
			res.copyFrom(c.mtx);
			
			while( c = c.parent ) 
				res.append(c.mtx);
			
			
			return res;
		}

		public function removeBlock( blockId : uint ) : void {
			if( blockId == 0 ) return;
			
//			if( _blocks[blockId].data ) trace( "awd.BaseParser - removeBl -- ",  blockId, _blocks[blockId].data , _blocks[blockId].data.name);
			
			_blocks[blockId].id = 0;
			_blocks[blockId].bounds.bytes = null;
			_blocks[blockId].bounds.length = 0;
			_blocks[blockId].bounds = null;
			
			_blocks.AS3::splice(blockId, 1);
			
			for ( var j : uint = blockId; j < _blocks.length; j++) 
				_blocks[j].id = j;
			
		}
		public function removeAsset(asset : NamedAsset ) : void {
			removeBlock( asset.block.id );
		}

		public function recompose() : ByteArray {
			
			var res : ByteArray = new ByteArray();
			res.endian = Endian.LITTLE_ENDIAN;
			
			
			
			// HEADER
			
			res.writeUTFBytes("AWD");
			
			
			res.writeByte( _version[0] );
			res.writeByte( _version[1] );
			
			// Parse bit flags and compression
			var flags : uint = 0;
			//_byteData.readUnsignedShort();
			if( _streaming )
				flags |= 0x1;
			if( _optimized_for_accuracy )
				flags |= 0x2;
			res.writeShort(flags);
			
			res.writeByte(_compression);
			

			
			
			// compute boby len
			var blen : uint = 0;
			for ( i = 1; i < _blocks.length; i++) {
				if( _blocks[i].data ) // if block is known
					_blocks[i].data.updateBlock();
				blen += _blocks[i].bounds.length;
			}
			
			blen += 10*(_blocks.length-1); // 10 bytes per block head
			res.writeUnsignedInt(blen); 
			
			
			// upadate ids and write
			
			
			var i : int;
			for ( i = 1; i < _blocks.length; i++) {
				res.writeUnsignedInt(i);
				res.writeByte( 0 );
				res.writeByte( _blocks[i].type );
				res.writeUnsignedInt(_blocks[i].bounds.length );
				res.writeBytes( _blocks[i].bounds.bytes,_blocks[i].bounds.position, _blocks[i].bounds.length );
				
//				if( _blocks[i].data ) trace( "awd.BaseParser - recompose -- ",  i, _blocks[i].data , _blocks[i].data.name);
			}
			
			
			return res;
		}

		
	}
}




internal dynamic class AWDProperties
{
	public function set(key : uint, value : *) : void
	{
		this[key.AS3::toString()] = value;
	}
	
	public function get(key : uint, fallback : *) : *
	{
		if (this.hasOwnProperty(key.AS3::toString()))
			return this[key.AS3::toString()];
		else return fallback;
	}
}


include "misc/Matrix3D.as"
include "NamedAsset.as"
include "AWDBlock.as"
include "Material.as"
include "BytesBounds.as"
include "CompositeData.as"
include "Container.as"
include "Geometry.as"
include "Mesh.as"
include "SortTriangles.as"
include "SubGeometry.as"

