package awd {

	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * @author Pierre Lepers
	 * awd.ToLittleEndian
	 */
	public class ToLittleEndian {

		public static const UNCOMPRESSED : uint = 0;
		public static const DEFLATE : uint = 1;
		public static const LZMA : uint = 2;
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
		private var _byteData : ByteArray;
		private var _body : ByteArray;
		private var _result : ByteArray;

		public function ToLittleEndian(awd : ByteArray) {
			_byteData = awd;
			_byteData.endian = Endian.BIG_ENDIAN;

		}

		public function convert() : ByteArray {

			_result = new ByteArray();
			_result.endian = Endian.LITTLE_ENDIAN;
			
			_byteData.position = 8;
			_byteData.endian = Endian.LITTLE_ENDIAN;
			var lenB : uint =  _byteData.readUnsignedInt();
			
			if( lenB == _byteData.bytesAvailable ) {
				return null;
			}
			
			_byteData.endian = Endian.BIG_ENDIAN;
			_byteData.position = 0;
			parseHeader();

			while (_body.bytesAvailable > 0 ) {
				parseNextBlock();
			}

			_result.position = 0;
			
			return _result;
		}


		private function parseNextBlock() : void {
			var ns : uint, type : uint, len : uint;
			var id : uint
			_result.writeUnsignedInt(id =_body.readUnsignedInt());
			_result.writeByte(ns = _body.readUnsignedByte());
			_result.writeByte(type = _body.readUnsignedByte());
			_result.writeUnsignedInt(len = _body.readUnsignedInt());

			switch (type) {
				case 1:
					parseMeshData(len);
					break;
				case 22:
					parseContainer(len);
					break;
				case 24:
					parseMeshInstance(len);
					break;
				case 81:
					parseMaterial(len);
					break;
				// case 82:
				// assetData = parseTexture(len);
				// break;
				default:
//					trace('Ignoring block!', );
					_result.writeBytes(_body,_body.position, len);
					_body.position += len;
					break;
			}
		}

		private function parseMaterial(blockLength : uint) : void {
			var type : uint;
			var attributes : Object;
			var finalize : Boolean;
			var num_methods : uint;
			var methods_parsed : uint;
			
			var name : String = parseVarStr();
//			trace( "awd.ToLittleEndian - parseMaterial -- : ", name );
			_result.writeByte(type = _body.readUnsignedByte());
			_result.writeByte(num_methods = _body.readUnsignedByte());

			// Read material numerical properties
			// (1=color, 2=bitmap url, 11=alpha_blending, 12=alpha_threshold, 13=repeat)
			parseProperties({ 1:AWD_FIELD_INT32, 2:AWD_FIELD_BADDR, 
				11:AWD_FIELD_BOOL, 12:AWD_FIELD_FLOAT32, 13:AWD_FIELD_BOOL });

			methods_parsed = 0;
			while (methods_parsed < num_methods) {
				_result.writeShort(_body.readUnsignedShort());
				parseProperties(null);
				parseUserAttributes();
				methods_parsed++;
			}

			parseUserAttributes();
		}

		private function parseMeshInstance(blockLength : uint) : void {
			var name : String;
			var par_id : uint, data_id : uint;
			var num_materials : uint;
			var materials_parsed : uint;

			_result.writeUnsignedInt(par_id = _body.readUnsignedInt());
			parseMatrix3D();
			name = parseVarStr();
			
//			trace( "awd.ToLittleEndian - parseMeshInstance -- ",name );

			_result.writeUnsignedInt(data_id = _body.readUnsignedInt());

			_result.writeShort(num_materials = _body.readUnsignedShort());
			materials_parsed = 0;
			while (materials_parsed < num_materials) {
				_result.writeUnsignedInt(_body.readUnsignedInt());
				materials_parsed++;
			}

			// Ignore for now
			parseProperties({2 : AWD_FIELD_BADDR});

			parseUserAttributes();
		}

		private function parseContainer(blockLength : uint) : void {
			var name : String;
			var par_id : uint;

			_result.writeUnsignedInt(par_id = _body.readUnsignedInt());
			parseMatrix3D();
			name = parseVarStr();

			parseProperties(null);
			parseUserAttributes();
		}

		private function parseMeshData(blockLength : uint) : void {
			var name : String;
			var num_subs : uint;
			var subs_parsed : uint;
			var joints_per_vertex : int = -1;

			// Read name and sub count
			name = parseVarStr();
			
			
			_result.writeShort( num_subs = _body.readUnsignedShort() );

//			trace( "awd.ToLittleEndian - parseMeshData -- ", name, num_subs );

			// Read optional properties
			parseProperties({ 1:AWD_FIELD_MTX4x4, 2 : AWD_FIELD_BADDR });

			var isGComposite : Boolean = false;
			var subgeoms : Array = [];

			// Loop through sub meshes
			subs_parsed = 0;
			while (subs_parsed < num_subs) {
				var isComposite : Boolean = false;
				var mat_id : uint, sm_len : uint, sm_end : uint;
				var w_indices : Vector.<Number>;
				var weights : Vector.<Number>;

				_result.writeUnsignedInt(sm_len = _body.readUnsignedInt());
				sm_end = _body.position + sm_len;

				// Ignore for now
				parseProperties( null );

				// trace( "away3d.loaders.parsers.AWD2Parser - parseMeshData -- ", name );
				// Loop through data streams
				while (_body.position < sm_end) {
					var idx : uint = 0;
					var str_type : uint, str_len : uint, str_end : uint;

					_result.writeByte(str_type = _body.readUnsignedByte());
					_result.writeUnsignedInt(str_len = _body.readUnsignedInt());

					str_end = _body.position + str_len;

					var x : Number, y : Number, z : Number;

//					 trace( "away3d.loaders.parsers.AWD2Parser - parseMeshData -- type", str_type );

					if (str_type == 1) {
						while (_body.position < str_end) {
							_result.writeFloat(_body.readFloat());
							_result.writeFloat(_body.readFloat());
							_result.writeFloat(_body.readFloat());
						}
					} else if (str_type == 8 ) {
						isGComposite = isComposite = true;
						var gid : uint;
						var glen : uint;
						var k : int;
						while (_body.position < str_end) {
							_result.writeShort(gid = _body.readUnsignedShort());
							_result.writeShort(glen = _body.readUnsignedShort());
//							trace( "awd.ToLittleEndian - parseMeshData -- glen  ",glen );
							for (k = 0; k < glen; k++) {
								_result.writeShort(_body.readUnsignedShort());
							}
						}
					} else if (str_type == 2) {
						while (_body.position < str_end) {
							_result.writeShort(_body.readUnsignedShort());
						}
					} else if (str_type == 3 || str_type == 4 || str_type == 9 || str_type == 7) {
						while (_body.position < str_end) {
							_result.writeFloat(_body.readFloat());
						}
					} else if (str_type == 6) {
						while (_body.position < str_end) {
							_result.writeShort(_body.readUnsignedShort());
						}
					} else {
						throw new Error("awd.ToLittleEndian - parseMeshData : unhandle " + str_type.AS3::toString(16));
						_body.position = str_end;
					}
				}
				
				subs_parsed++;

				// Ignore sub-mesh attributes for now
				parseUserAttributes();
			}

			parseUserAttributes();
		}

		private function parseVarStr() : String {
			var len : uint;
			var res : String;
			_result.writeShort(len = _body.readUnsignedShort());
			_result.writeUTFBytes(res = _body.readUTFBytes(len));
			return res;
		}

		private function parseProperties(expected : Object) : void {
			var list_end : uint;
			var list_len : uint;

			_result.writeUnsignedInt(list_len = _body.readUnsignedInt());
			list_end = _body.position + list_len;

			if (expected) {
				while (_body.position < list_end) {
					var len : uint;
					var key : uint;
					var type : uint;

					_result.writeShort(key = _body.readUnsignedShort());
					_result.writeShort(len = _body.readUnsignedShort());
					
					if (expected.hasOwnProperty(key)) {
						type = expected[key];
						parseAttrValue(type, len);
					} else {
						_result.writeBytes(_body,_body.position, len);
						_body.position += len;
					}
				}
				
			} else {
				//_result.writeBytes(_body,_body.position, list_len);
				_body.position = list_end;
			}
		}

		private function parseAttrValue(type : uint, len : uint) : * {
			var elem_len : uint;
			var read_func : Function;
			var write_func : Function;

			switch (type) {
				case AWD_FIELD_INT8:
					elem_len = 1;
					read_func = _body.readByte;
					write_func = _result.writeByte;
					break;
				case AWD_FIELD_INT16:
					elem_len = 2;
					read_func = _body.readShort;
					write_func = _result.writeShort;
					break;
				case AWD_FIELD_INT32:
					elem_len = 4;
					read_func = _body.readInt;
					write_func = _result.writeInt;
					break;
				case AWD_FIELD_BOOL:
				case AWD_FIELD_UINT8:
					elem_len = 1;
					read_func = _body.readUnsignedByte;
					write_func = _result.writeByte;
					break;
				case AWD_FIELD_UINT16:
					elem_len = 2;
					read_func = _body.readUnsignedShort;
					write_func = _result.writeShort;
					break;
				case AWD_FIELD_UINT32:
				case AWD_FIELD_BADDR:
					elem_len = 4;
					read_func = _body.readUnsignedInt;
					write_func = _result.writeUnsignedInt;
					break;
				case AWD_FIELD_FLOAT32:
					elem_len = 4;
					read_func = _body.readFloat;
					write_func = _result.writeFloat;
					break;
				case AWD_FIELD_FLOAT64:
					elem_len = 8;
					read_func = _body.readDouble;
					write_func = _result.writeDouble;
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
					write_func = _result.writeDouble;
					break;
				default :
					throw new Error("awd.ToLittleEndian - parseAttrValue : " + type);
			}

			var val : *;

			if (elem_len < len) {
				var list : Array;
				var num_read : uint;
				var num_elems : uint;

				list = [];
				num_read = 0;
				num_elems = len / elem_len;
				while (num_read < num_elems) {
					write_func(val = read_func());
					list.push(val);
					num_read++;
				}

				return list;
			} else {
				write_func(val = read_func());
				return val;
			}
		}

		private function parseUserAttributes() : void {
			var list_len : uint;

			_result.writeUnsignedInt(list_len = _body.readUnsignedInt());

			if (list_len > 0) {
				var list_end : uint;

				list_end = _body.position + list_len;
				while (_body.position < list_end) {
					var ns_id : uint;
					var attr_type : uint;
					var attr_len : uint;

					// TODO: Properly tend to namespaces in attributes
					_result.writeByte(ns_id = _body.readUnsignedByte());
					parseVarStr();
					_result.writeByte(attr_type = _body.readUnsignedByte());
					_result.writeShort(attr_len = _body.readUnsignedShort());

					switch (attr_type) {
						case AWD_FIELD_STRING:
							_result.writeUTFBytes(_body.readUTFBytes(attr_len));
							break;
						default:
							_result.writeBytes(_body,_body.position, attr_len);
							_body.position += attr_len;
							break;
					}
				}
			}
		}

		private function parseMatrix3D() : void {
			parseMatrixRawData();
		}

		private function parseMatrixRawData(len : uint = 16) : void {
			var i : uint;
			for (i = 0; i < len; i++)
				_result.writeFloat(_body.readFloat());
		}

		private function parseHeader() : void {
			var flags : uint;
			var body_len : Number;

			// Skip magic string and parse version
			_result.writeUTFBytes(_byteData.readUTFBytes(3));

			_result.writeByte(_byteData.readUnsignedByte());
			_result.writeByte(_byteData.readUnsignedByte());

			// Parse bit flags and compression
			_result.writeShort(_byteData.readUnsignedShort());

			var compression : uint = _byteData.readUnsignedByte();
			_result.writeByte(compression);

			// Check file integrity
			_result.writeUnsignedInt(_byteData.readUnsignedInt());

			switch (compression) {
				case DEFLATE:
					_body = new ByteArray;
					_byteData.readBytes(_body, 0, _byteData.bytesAvailable);
					_body.uncompress();
					break;
				case LZMA:
					// TODO: Decompress LZMA into _body
					break;
				case UNCOMPRESSED:
					_body = _byteData;
					break;
			}
		}
	}
}
