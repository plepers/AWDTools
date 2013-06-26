package awd {

	import flash.utils.ByteArray;
	/**
	 * @author Pierre Lepers
	 * awd.Dump
	 */
	public class Dump extends BaseParser {
		
		private var _sizeReport : String;

		public function Dump(awd : ByteArray) {
			super( awd );
			
			_dump();
		}

		private function _dump() : void {
			
			_sizeReport = "";
			
			for (var i : int = 0; i < _blocks.length; i++) {
				
				_dumpBlock( _blocks[i] );
				
			}
			
			trace( _sizeReport );
			
		}

		private function _dumpBlock(block : AWDBlock) : void {
			
			trace( "  #"+block.id+" ["+getBlockType( block.type )+ "]" );
			if( block.data )
				_sizeReport += "\n  "+block.data.name+"	"+ formatSize( block.bounds.length );
			switch(block.type){
				case BaseParser.BLOCK_CONTAINER:
					_dumpContainer( block );
					break;
				case BaseParser.BLOCK_MATERIAL:
					_dumpMaterial( block );
					break;
				case BaseParser.BLOCK_MESHDATA:
					_dumpGeom( block );
					break;
				case BaseParser.BLOCK_MESHINST:
					_dumpMesh( block );
					break;
			}
			
			trace( " " ); // nl
		}

		private function _dumpMesh(block : AWDBlock) : void {
			var mesh : Mesh = block.data as Mesh;
			
			trace( "    name : 		"+mesh.name );
			trace( "    parent : 	"+( mesh.parent? mesh.parent.name: "-" ) );
			trace( "    geom : 		#"+mesh.geom.block.id+ " ("+mesh.geom.name+")" );
			var mlist : String = "";
			for (var i : int = 0; i < mesh.materials.length; i++) 
				mlist += mesh.materials[i].name + "' ";
			
			trace( "    materials : "+mlist );
		}

		private function _dumpGeom(block : AWDBlock) : void {

			var geom : Geometry= block.data as Geometry;

			trace( "    name :		"+geom.name );
			trace( "    subs :		"+geom.subs.length );
			for (var i : int = 0; i < geom.subs.length; i++) {
				trace( "      #"+i+"  "+ (( geom.subs[i].compositeData != null ) ? "(composite)":""));
				dumpSubgeom( geom.subs[i] );
				
			}
			
		}

		private function dumpSubgeom(sg : SubGeometry) : void {
			
			trace( "        vertices : 	"+sg.verticesBounds.length/12 );
			
			_sizeReport += "\n        vertices : 	"+ formatSize( sg.verticesBounds.length );
			
			if( sg.indicesBounds ) {
				trace( "        tris :		"+sg.indicesBounds.length/6 );
				_sizeReport += "\n        tris : 		"+ formatSize( sg.verticesBounds.length );
			} else {
				trace( "        composites :		"+sg.compositeData.groupIds.length );
				var cid : uint;
				var cize : uint = 0;
				for (var i : int = 0; i < sg.compositeData.groupIds.length; i++) {
					cid = sg.compositeData.groupIds[i];
					trace( "          #"+cid+" "+sg.compositeData.dGroups[ cid ].length/6+" tris" );
					cize += sg.compositeData.dGroups[ cid ].length;
				}
				_sizeReport += "\n        composites : 	"+ formatSize( cize );
			}




			var streams : Array = [];
			if( sg.normalsBounds ) {
				streams.push("NRM");
				_sizeReport += "\n        normals : 	"+ formatSize( sg.normalsBounds.length );
			}
			if( sg.uvsBounds ) {
				streams.push("UVS");
				_sizeReport += "\n        uvs :		"+ formatSize( sg.uvsBounds.length );
			}
			if( sg.colorsBounds ) {
				streams.push("CLR");
				_sizeReport += "\n        colors : 	"+ formatSize( sg.colorsBounds.length );
			}
			trace( "        ["+streams.join(", ")+"]" );
			
		}

		private function _dumpMaterial(block : AWDBlock) : void {
			
			var mat : Material = block.data as Material;
			trace( "    name :		"+ mat.name);
		}

		private function _dumpContainer(block : AWDBlock) : void {
			var c : Container= block.data as Container;

			trace( "    name :		"+c.name );
		}

		private function getBlockType( typeId : uint ) : String {
			switch(typeId){
				case BaseParser.BLOCK_CONTAINER:
					return "Container";
				case BaseParser.BLOCK_MATERIAL:
					return "Material";
				case BaseParser.BLOCK_MESHDATA:
					return "Geometry";
				case BaseParser.BLOCK_MESHINST:
					return "Mesh";
			}
			return "unknown";
		}

		private function formatSize( size : uint ) : String {
			var res : String;
			if( size  > 10*1024 ) 
				res = Math.round(size /1024) + " ko";
			else
				res = size + " o";
				
			res = spaces.AS3::substr( 0 , 20- res.length )+res;
				
			return res;
		}
		
		private const spaces : String = "                                                                ";
		
		
	}
}
