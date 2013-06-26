package awd {

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	/**
	 * @author Pierre Lepers
	 * awd.CleanMaterials
	 */
	public class CleanMaterials extends BaseParser {
		
		public function CleanMaterials(awd : ByteArray) {

			super(awd);

			_clean();
		}

		private function _clean() : void {
			
			var i:int,l:int;
			
			var names :Dictionary= new Dictionary();
			var remaps : Dictionary = new Dictionary();
			var toRemove : Vector.<AWDBlock>= new Vector.<AWDBlock>();
			var mat : Material;
			
			for (var j : int = 1; j < _blocks.length; j++) {
				if ( _blocks[j].data && _blocks[j].data is Material  ) {
					
					mat = _blocks[j].data as Material;
					
					if( names[ mat.name ] != undefined ) {
						// already exist
						remaps[ _blocks[j].id ] = names[ mat.name ];
//						trace( "awd.CleanMaterials - _clean -- remove mat ",mat.name, _blocks[j].id );
						toRemove.AS3::push( _blocks[j] );
					} 
					else {
						// don't exist
						names[ mat.name ] = mat;
					}
					mat.block.id;
					
				}
					
			}
			
			
			var mesh : Mesh;
			for ( j = 1; j < _blocks.length; j++) {
				if ( _blocks[j].data && _blocks[j].data is Mesh  ) {
					mesh = _blocks[j].data as Mesh;
					
					for ( i  = 0, l = mesh.materials.length; i < l; i++) {
						mat = mesh.materials[i];
						if( remaps[ mat.block.id ] != undefined ) {
//							trace( "replace mesh mat ", mesh.name, mat.name, i)
							mesh.materials[i] = remaps[ mat.block.id ];
						}
					}
					
				}
			}
			
			for (i = 0, l = toRemove.length; i < l; i++) {
				removeBlock( toRemove[i].id );
			}
			
		}
		
	}
}
