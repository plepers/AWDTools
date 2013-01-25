package awd {

	import awd.BaseParser;

	import flash.utils.ByteArray;

	/**
	 * @author Pierre Lepers
	 * awd.TriangleSorter
	 */
	public class TriangleSorter extends BaseParser {

		private var _meshName : String;
		private var _subgeom : uint;

		public function TriangleSorter(awd : ByteArray, meshName : String, subgeom : uint) {
			_subgeom = subgeom;
			_meshName = meshName;
			super(awd);
			
			_sort();
			
		}

		private function _sort() : void {
			var mesh : Mesh = findMesh(_meshName);
			
			if( mesh == null ) throw new Error( "awd.TriangleSorter - _sort : no mesh "+_meshName );
			
			var subGeom : SubGeometry = mesh.geom.subs[ _subgeom ];
			
			var verts : BytesBounds = subGeom.verticesBounds;
			
			
			
		}
	}
}

class Face {
	
	public var cgeom : uint = 0;
	
	public var i1 : uint;
	public var i2 : uint;
	public var i3 : uint;
	
	public var px : Number;
	public var py : Number;
	public var pz : Number;
	
}
