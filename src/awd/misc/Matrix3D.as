package awd.misc {

	import flash.utils.Endian;
	import flash.utils.ByteArray;

	/**
	 * @author Pierre Lepers
	 * awd.misc.Matrix3D
	 */
	public class Matrix3D {
		
		private static function _createBuff() : ByteArray {
			var re : ByteArray = new ByteArray();
			re.endian = Endian.LITTLE_ENDIAN;
			return re;
		}
		private static const BUFFER : ByteArray = _createBuff();

		private static const EPSILON : Number= 0.000000001;


		public var raw : Vector.<Number>;

		public function Matrix3D(raw : Vector.<Number> = null) {
			if ( raw == null ) {
				raw = new <Number>[ 
					1.0, 0.0, 0.0, 0.0, 
					0.0, 1.0, 0.0, 0.0, 
					0.0, 0.0, 1.0, 0.0, 
					0.0, 0.0, 0.0, 1.0];
			}
			this.raw = raw;
		}

		public function identity() : void {
			var te : Vector.<Number> = this.raw;

			te[0] = 1.0;
			te[4] = 0.0;
			te[8] = 0.0;
			te[12] = 0.0;
			te[1] = 0.0;
			te[5] = 1.0;
			te[9] = 0.0;
			te[13] = 0.0;
			te[2] = 0.0;
			te[6] = 0.0;
			te[10] = 1.0;
			te[14] = 0.0;
			te[3] = 0.0;
			te[7] = 0.0;
			te[11] = 0.0;
			te[15] = 1.0;
		}

		public function transpose() : void {
			var te : Vector.<Number> = raw;
			var tmp : Number;
	
			tmp = te[1]; te[1] = te[4]; te[4] = tmp;
			tmp = te[2]; te[2] = te[8]; te[8] = tmp;
			tmp = te[6]; te[6] = te[9]; te[9] = tmp;
	
			tmp = te[3]; te[3] = te[12]; te[12] = tmp;
			tmp = te[7]; te[7] = te[13]; te[13] = tmp;
			tmp = te[11]; te[11] = te[14]; te[14] = tmp;
			
		}

		public function prepend(m : Matrix3D) : void {
			var ae : Vector.<Number> = raw;
			var be : Vector.<Number> = m.raw;

			var a11 : Number = ae[0], a12 : Number = ae[4], a13 : Number = ae[8], a14 : Number = ae[12];
			var a21 : Number = ae[1], a22 : Number = ae[5], a23 : Number = ae[9], a24 : Number = ae[13];
			var a31 : Number = ae[2], a32 : Number = ae[6], a33 : Number = ae[10], a34 : Number = ae[14];
			var a41 : Number = ae[3], a42 : Number = ae[7], a43 : Number = ae[11], a44 : Number = ae[15];

			var b11 : Number = be[0], b12 : Number = be[4], b13 : Number = be[8], b14 : Number = be[12];
			var b21 : Number = be[1], b22 : Number = be[5], b23 : Number = be[9], b24 : Number = be[13];
			var b31 : Number = be[2], b32 : Number = be[6], b33 : Number = be[10], b34 : Number = be[14];
			var b41 : Number = be[3], b42 : Number = be[7], b43 : Number = be[11], b44 : Number = be[15];

			ae[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
			ae[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
			ae[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
			ae[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

			ae[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
			ae[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
			ae[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
			ae[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

			ae[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
			ae[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
			ae[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
			ae[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

			ae[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
			ae[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
			ae[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
			ae[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
		}

		public function append(m : Matrix3D) : void {
			var ae : Vector.<Number> = raw;
			var be : Vector.<Number> = m.raw;

			var a11 : Number = be[0], a12 : Number = be[4], a13 : Number = be[8], a14 : Number =  be[12];
			var a21 : Number = be[1], a22 : Number = be[5], a23 : Number = be[9], a24 : Number =  be[13];
			var a31 : Number = be[2], a32 : Number = be[6], a33 : Number = be[10], a34 : Number = be[14];
			var a41 : Number = be[3], a42 : Number = be[7], a43 : Number = be[11], a44 : Number = be[15];
                                                                                                   
			var b11 : Number = ae[0], b12 : Number = ae[4], b13 : Number = ae[8], b14 : Number =  ae[12];
			var b21 : Number = ae[1], b22 : Number = ae[5], b23 : Number = ae[9], b24 : Number =  ae[13];
			var b31 : Number = ae[2], b32 : Number = ae[6], b33 : Number = ae[10], b34 : Number = ae[14];
			var b41 : Number = ae[3], b42 : Number = ae[7], b43 : Number = ae[11], b44 : Number = ae[15];

			ae[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
			ae[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
			ae[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
			ae[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

			ae[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
			ae[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
			ae[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
			ae[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

			ae[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
			ae[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
			ae[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
			ae[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

			ae[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
			ae[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
			ae[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
			ae[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
		}

		public function invert() : void {
			
			var me : Vector.<Number> = this.raw;

			var n11 : Number = me[0], n12 : Number = me[4], n13 : Number = me[8], n14  : Number= me[12];
			var n21 : Number = me[1], n22 : Number = me[5], n23 : Number = me[9], n24  : Number= me[13];
			var n31 : Number = me[2], n32 : Number = me[6], n33 : Number = me[10], n34 : Number = me[14];
			var n41 : Number = me[3], n42 : Number = me[7], n43 : Number = me[11], n44 : Number = me[15];
	
			me[0] = n23*n34*n42 - n24*n33*n42 + n24*n32*n43 - n22*n34*n43 - n23*n32*n44 + n22*n33*n44;
			me[4] = n14*n33*n42 - n13*n34*n42 - n14*n32*n43 + n12*n34*n43 + n13*n32*n44 - n12*n33*n44;
			me[8] = n13*n24*n42 - n14*n23*n42 + n14*n22*n43 - n12*n24*n43 - n13*n22*n44 + n12*n23*n44;
			me[12] = n14*n23*n32 - n13*n24*n32 - n14*n22*n33 + n12*n24*n33 + n13*n22*n34 - n12*n23*n34;
			me[1] = n24*n33*n41 - n23*n34*n41 - n24*n31*n43 + n21*n34*n43 + n23*n31*n44 - n21*n33*n44;
			me[5] = n13*n34*n41 - n14*n33*n41 + n14*n31*n43 - n11*n34*n43 - n13*n31*n44 + n11*n33*n44;
			me[9] = n14*n23*n41 - n13*n24*n41 - n14*n21*n43 + n11*n24*n43 + n13*n21*n44 - n11*n23*n44;
			me[13] = n13*n24*n31 - n14*n23*n31 + n14*n21*n33 - n11*n24*n33 - n13*n21*n34 + n11*n23*n34;
			me[2] = n22*n34*n41 - n24*n32*n41 + n24*n31*n42 - n21*n34*n42 - n22*n31*n44 + n21*n32*n44;
			me[6] = n14*n32*n41 - n12*n34*n41 - n14*n31*n42 + n11*n34*n42 + n12*n31*n44 - n11*n32*n44;
			me[10] = n12*n24*n41 - n14*n22*n41 + n14*n21*n42 - n11*n24*n42 - n12*n21*n44 + n11*n22*n44;
			me[14] = n14*n22*n31 - n12*n24*n31 - n14*n21*n32 + n11*n24*n32 + n12*n21*n34 - n11*n22*n34;
			me[3] = n23*n32*n41 - n22*n33*n41 - n23*n31*n42 + n21*n33*n42 + n22*n31*n43 - n21*n32*n43;
			me[7] = n12*n33*n41 - n13*n32*n41 + n13*n31*n42 - n11*n33*n42 - n12*n31*n43 + n11*n32*n43;
			me[11] = n13*n22*n41 - n12*n23*n41 - n13*n21*n42 + n11*n23*n42 + n12*n21*n43 - n11*n22*n43;
			me[15] = n12*n23*n31 - n13*n22*n31 + n13*n21*n32 - n11*n23*n32 - n12*n21*n33 + n11*n22*n33;
			
			var s : Number = 1 / determinant();
			
			me[0] *= s; me[4] *= s; me[8] *= s;
			me[1] *= s; me[5] *= s; me[9] *= s;
			me[2] *= s; me[6] *= s; me[10] *=s;
			me[3] *= s; me[7] *= s; me[11] *=s;	
			
		}

		public function determinant() : Number {
			
			var me : Vector.<Number> = raw;

			var n11 : Number = me[0], n12 : Number = me[4], n13 : Number = me[8], n14  : Number= me[12];
			var n21 : Number = me[1], n22 : Number = me[5], n23 : Number = me[9], n24  : Number= me[13];
			var n31 : Number = me[2], n32 : Number = me[6], n33 : Number = me[10], n34 : Number = me[14];
			var n41 : Number = me[3], n42 : Number = me[7], n43 : Number = me[11], n44 : Number = me[15];
			
			//TODO: make this more efficient
			//( based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm )
	
			return (
				n14 * n23 * n32 * n41-
				n13 * n24 * n32 * n41-
				n14 * n22 * n33 * n41+
				n12 * n24 * n33 * n41+
	
				n13 * n22 * n34 * n41-
				n12 * n23 * n34 * n41-
				n14 * n23 * n31 * n42+
				n13 * n24 * n31 * n42+
	
				n14 * n21 * n33 * n42-
				n11 * n24 * n33 * n42-
				n13 * n21 * n34 * n42+
				n11 * n23 * n34 * n42+
	
				n14 * n22 * n31 * n43-
				n12 * n24 * n31 * n43-
				n14 * n21 * n32 * n43+
				n11 * n24 * n32 * n43+
	
				n12 * n21 * n34 * n43-
				n11 * n22 * n34 * n43-
				n13 * n22 * n31 * n44+
				n12 * n23 * n31 * n44+
	
				n13 * n21 * n32 * n44-
				n11 * n23 * n32 * n44-
				n12 * n21 * n33 * n44+
				n11 * n22 * n33 * n44
			);
		
		}


		public function scale( x : Number, y : Number, z : Number) : void {
			
			var te : Vector.<Number> = raw;
	
			te[0] *= x; te[4] *= y; te[8] *= z;
			te[1] *= x; te[5] *= y; te[9] *= z;
			te[2] *= x; te[6] *= y; te[10] *= z;
			te[3] *= x; te[7] *= y; te[11] *= z;
			
		}



		/**
		 * @offset input offset
		 */
		public function transformBytes(input : ByteArray, output : ByteArray, length : uint, offset : uint = 0) : void {
			var i : int = 0;
			
			var copy : Boolean = ( input == output );
			var ouputPosition : uint = output.position;
			
			if( copy ) {
				output = BUFFER;
				output.position = 0;
			}

			input.position = offset;
			

			var vx : Number, vy : Number, vz : Number;
			var me : Vector.<Number> = raw;
			
			var n11 : Number = me[0], n12 : Number = me[4], n13 : Number = me[8], n14  : Number= me[12];
			var n21 : Number = me[1], n22 : Number = me[5], n23 : Number = me[9], n24  : Number= me[13];
			var n31 : Number = me[2], n32 : Number = me[6], n33 : Number = me[10], n34 : Number = me[14];

			if( Math.abs( me[3]  ) > EPSILON || 
				Math.abs( me[7]  ) > EPSILON || 
				Math.abs( me[11] ) > EPSILON || 
				Math.abs( 1.0-me[15] )> EPSILON )
				throw new Error( "awd.misc.Matrix3D - transformBytes : perspective not supported"+ me[3]+"  "+ me[7]+"  "+me[11]+"  "+ me[15] );
			
			while ( i++ < length ) {
				vx = input.readFloat();
				vy = input.readFloat();
				vz = input.readFloat();

				//d = 1 / ( te[3] * vx + te[7] * vy + te[11] * vz + te[15] );
				output.writeFloat ( ( n11 * vx + n12 * vy + n13 * vz + n14  ) );//* d );
				output.writeFloat ( ( n21 * vx + n22 * vy + n23 * vz + n24  ) );//* d );
				output.writeFloat ( ( n31 * vx + n32 * vy + n33 * vz + n34  ) );//* d);
			}
			
			if( copy ) {
				output.position = ouputPosition;
				output.writeBytes( BUFFER, 0, length*12 );
			}
			
		}
		
		/**
		 * @offset input offset
		 */
		public function deltaTransformBytes(input : ByteArray, output : ByteArray, length : uint, offset : uint = 0) : void {
			var i : int = 0;
			
			var copy : Boolean = ( input == output );
			var ouputPosition : uint = output.position;
			
			if( copy ) {
				output = BUFFER;
				output.position = 0;
			}

			input.position = offset;
			

			var vx : Number, vy : Number, vz : Number;
			var me : Vector.<Number> = raw;
			
			var n11 : Number = me[0], n12 : Number = me[4], n13 : Number = me[8];
			var n21 : Number = me[1], n22 : Number = me[5], n23 : Number = me[9];
			var n31 : Number = me[2], n32 : Number = me[6], n33 : Number = me[10];

			if( Math.abs( me[3]  ) > EPSILON || 
				Math.abs( me[7]  ) > EPSILON || 
				Math.abs( me[11] ) > EPSILON || 
				Math.abs( 1.0-me[15] )> EPSILON )
				throw new Error( "awd.misc.Matrix3D - deltaTransformBytes : perspective not supported" );

			while ( i++ < length ) {
				vx = input.readFloat();
				vy = input.readFloat();
				vz = input.readFloat();

				//d = 1 / ( te[3] * vx + te[7] * vy + te[11] * vz + te[15] );

				output.writeFloat ( ( n11 * vx + n12 * vy + n13 * vz ) );//* d );
				output.writeFloat ( ( n21 * vx + n22 * vy + n23 * vz ) );//* d );
				output.writeFloat ( ( n31 * vx + n32 * vy + n33 * vz ) );//* d);
			}
			
			if( copy ) {
				input.position = ouputPosition;
				input.writeBytes( BUFFER, 0, length );
			}
			
		}

		public function copyFrom(m : Matrix3D) : void {
			var ae : Vector.<Number> = m.raw;
			var be : Vector.<Number> = raw;

			for (var i : int = 0; i < 16; i++) {
				be[i] = ae[i];
			}
		}

		public function clone() : Matrix3D {
			var res : Matrix3D = new Matrix3D();
			res.copyFrom(this);
			return res;
		}
		
		public function toString() : String {
			var s : String = 
			
			"	"+raw[0] .AS3::toFixed(3)+"	"+raw[1] .AS3::toFixed(3)+"	"+raw[2] .AS3::toFixed(3)+"	"+ raw[3] .AS3::toFixed(3)+"\n"+
			"	"+raw[4] .AS3::toFixed(3)+"	"+raw[5] .AS3::toFixed(3)+"	"+raw[6] .AS3::toFixed(3)+"	"+ raw[7] .AS3::toFixed(3)+"\n"+
			"	"+raw[8] .AS3::toFixed(3)+"	"+raw[9] .AS3::toFixed(3)+"	"+raw[10].AS3::toFixed(3)+"	"+ raw[11].AS3::toFixed(3)+"\n"+
			"	"+raw[12].AS3::toFixed(3)+"	"+raw[13].AS3::toFixed(3)+"	"+raw[14].AS3::toFixed(3)+"	"+ raw[15].AS3::toFixed(3)+"\n";
			
			return s;
		}
	}
	// flash.geom.Matrix3D
}
