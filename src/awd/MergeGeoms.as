package awd {

	import awd.misc.Matrix3D;

	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * @author Pierre Lepers
	 * awd.MergeGeoms
	 */
	public class MergeGeoms extends BaseParser {

		private const DEFAULT_COMPOSITE_GROUP : uint = 99;
		private const LIMIT : uint = 196605;
		private var _receiver : String;
		private var _meshes : Vector.<String>;
		private var _vectorsSource : Vector.<DataSubGeometry>;
		private var _meshToRemove : Vector.<Mesh>;
		private var _injected : Vector.<DataSubGeometry>;
		private var _meshesFounds : Vector.<Mesh>;

		public function MergeGeoms(awd : ByteArray, receiver : String, meshes : Vector.<String>) {
			_meshes = meshes;
			_receiver = receiver;

			super(awd);

			_merge();
		}

		private function _merge() : void {
			_vectorsSource = new Vector.<DataSubGeometry>();
				
			_meshesFounds = new Vector.<Mesh>();
			for (var i : uint = 0;i < _meshes.length;i++)
				collect(_meshes[i]);
			_meshesFounds = null;
			
			_meshToRemove = new Vector.<Mesh>();
			_injected = new Vector.<DataSubGeometry>();
			
			merge(findMesh(_receiver));

			removeMeshes();
			
			_meshToRemove = null;
		}

		private function addRemoving( m : Mesh ) : void {
			if( _meshToRemove.AS3::indexOf( m ) == -1)
				_meshToRemove.AS3::push( m );
		}

		
		private function removeMeshes() : void {
			var numSubs : int = 0
			
			for (var i : int = 0; i < _meshToRemove.length; i++) {
				removeAsset(_meshToRemove[i]);
				// assume geom has no other use
				removeAsset(_meshToRemove[i].geom);
				numSubs += _meshToRemove[i].geom.num_subs;
			}
			
			var ilist : String = "";
			
			for (i  = 0; i < _injected.length; i++) {
				ilist += _injected[i].mesh.name+",";
			}
			
			trace( _injected.length, "subs added to" , _receiver, ":", ilist );
			trace( _meshToRemove.length, "meshes removed" );
			trace( numSubs, "renderables removed" );
		}

		private function merge(destMesh : Mesh) : void {
			var i : uint;
			// var vecLength : uint;
			// var numVerts : uint;
			var subGeom : SubGeometry;
			var cgeom : SubGeometry;
			var ds : DataSubGeometry;

			var geometry : Geometry = destMesh.geom;
			var geometries : Vector.<SubGeometry> = geometry.subs;
			var numSubGeoms : uint = geometries.length;

			var vertices : BytesBounds;
			var normals : BytesBounds;
			var indices : BytesBounds;
			var uvs : BytesBounds;
			var colors : BytesBounds;
			var vectors : Vector.<DataSubGeometry> = new Vector.<DataSubGeometry>();

			var destSceneTransform : Matrix3D = getSceneTransform(destMesh);
			var destInvertSceneTransform : Matrix3D = destSceneTransform.clone();
			destInvertSceneTransform.invert();

			// empty mesh receiver case
			if (numSubGeoms == 0) {
				throw new Error("awd.MergeGeoms - merge : empty receiver");
			}

			for (i = 0; i < numSubGeoms; ++i) {
				cgeom = geometries[i] as SubGeometry;
				vertices = cgeom.verticesBounds;
				normals = cgeom.normalsBounds;
				indices = cgeom.indicesBounds;
				uvs = cgeom.uvsBounds;
				colors = cgeom.colorsBounds;

				vertices.extract();
				if ( normals ) normals.extract();
				if ( uvs ) uvs.extract();
				if ( colors ) colors.extract();

				if ( indices )
					indices.extract();
				else
					cgeom.compositeData.extract();

				ds = new DataSubGeometry();
				ds.subGeomIndex = i;
				ds.subGeometry = cgeom;
				ds.mesh = destMesh;
				ds.material = cgeom.material || destMesh.materials[0];
				ds.sceneTransform = destSceneTransform.clone();
				ds.invertSceneTransform = destInvertSceneTransform.clone();

				vectors.AS3::push(ds);
			}

			var nvertices : BytesBounds;
			var nindices : BytesBounds;
			var ncolors : BytesBounds;
			var nuvs : BytesBounds;
			var nnormals : BytesBounds;

			var destDs : DataSubGeometry = ds;
			nvertices = ds.subGeometry.verticesBounds;
			nindices = ds.subGeometry.indicesBounds;
			nuvs = ds.subGeometry.uvsBounds;
			nnormals = ds.subGeometry.normalsBounds;
			ncolors = ds.subGeometry.colorsBounds;

			// var activeMaterial:uint = ds.material;

			numSubGeoms = _vectorsSource.length;

			// TODO scale ???
			var scale : Boolean = false;
			// (destMesh.scaleX != 1 || destMesh.scaleY != 1 || destMesh.scaleZ != 1);

			for (i = 0; i < numSubGeoms; ++i) {
				ds = _vectorsSource[i];
				subGeom = ds.subGeometry;
				vertices = ds.subGeometry.verticesBounds;
				normals = ds.subGeometry.normalsBounds;
				indices = ds.subGeometry.indicesBounds;
				indices = ds.subGeometry.indicesBounds;
				uvs = ds.subGeometry.uvsBounds;

				if ( ds.material) {
					destDs = getDestSubgeom(vectors, ds);

					if (!destDs) {
						destDs = _vectorsSource[i];

						injectSubGeom(destDs, destInvertSceneTransform);
						destDs.sceneTransform = destSceneTransform.clone();
						destDs.invertSceneTransform = destInvertSceneTransform.clone();
						
						
						geometries.AS3::push( destDs.subGeometry );
						destMesh.materials.AS3::push( destDs.material );
						vectors.AS3::push(destDs);
						
						addRemoving(ds.mesh);
						
						continue;
					}

					// activeMaterial = destDs.material;
					nvertices = destDs.subGeometry.verticesBounds;
					nnormals = destDs.subGeometry.normalsBounds;
					nindices = destDs.subGeometry.indicesBounds;
					nuvs = destDs.subGeometry.uvsBounds;
					ncolors = destDs.subGeometry.colorsBounds;
				} else {
					throw new Error( "awd.MergeGeoms - merge : no Mat" );
				}

				appendSubGeom(ds, destDs);

				addRemoving(ds.mesh);
			}

			vectors = _vectorsSource = null;
		}

		public function injectSubGeom(sg : DataSubGeometry, transform : Matrix3D) : void {
			var xform : Matrix3D = sg.sceneTransform.clone();
			xform.append(transform);
			
			_injected.AS3::push( sg );
			
			
			
			var sub : SubGeometry = sg.subGeometry;

			var b : BytesBounds;
			var be : BytesBounds;
			
			b = sub.verticesBounds.clone();
			be = sub.verticesBounds;
			be.extract();
			be.bytes.position = 0;
			xform.transformBytes(b.bytes, be.bytes, b.length/12, b.position);

			if ( sub.normalsBounds ) {
				b = sub.normalsBounds.clone();
				be = sub.normalsBounds;
				be.extract();
				be.bytes.position = 0;
				xform.deltaTransformBytes(b.bytes, be.bytes, b.length/12, b.position);
			}

			if ( sub.uvsBounds )
				sub.uvsBounds.extract();
			if ( sub.colorsBounds )
				sub.colorsBounds.extract();

			if ( sub.indicesBounds )
				sub.indicesBounds.extract();
			else {
				throw new Error( "awd.MergeGeoms - injectSubGeom : " );
			}
		}

		public function appendSubGeom(source : DataSubGeometry, dest : DataSubGeometry) : void {
			var xform : Matrix3D = source.sceneTransform.clone();
			xform.append(dest.invertSceneTransform);

			var sub : SubGeometry = source.subGeometry;
			var dsub : SubGeometry = dest.subGeometry;

			var indexOffset : uint = dsub.verticesBounds.length / 12;
			var numIndices : uint;
			var i : uint;

			dsub.verticesBounds.seekToEnd();
			dsub.verticesBounds.length += sub.verticesBounds.length;

			if ( dsub.verticesBounds.length + 9 > LIMIT )
				throw new Error("awd.MergeGeoms - merge : broke vertices LIMIT", dsub.verticesBounds.length);
			
			
			// TODO no xform to test
			xform.transformBytes(sub.verticesBounds.bytes, dsub.verticesBounds.bytes, sub.verticesBounds.length/12, sub.verticesBounds.position);
//			dsub.verticesBounds.bytes.writeBytes(sub.verticesBounds.bytes, sub.verticesBounds.position, sub.verticesBounds.length);

			if ( sub.normalsBounds ) {
				dsub.normalsBounds.seekToEnd();
				dsub.normalsBounds.length += sub.normalsBounds.length;
				// TODO no xform to test
				xform.deltaTransformBytes(sub.normalsBounds.bytes, dsub.normalsBounds.bytes, sub.normalsBounds.length/12, sub.normalsBounds.position );
//				dsub.normalsBounds.bytes.writeBytes(sub.normalsBounds.bytes, sub.normalsBounds.position, sub.normalsBounds.length);
			}

			if ( sub.uvsBounds ) {
				dsub.uvsBounds.seekToEnd();
				dsub.uvsBounds.length += sub.uvsBounds.length;
				dsub.uvsBounds.bytes.writeBytes(sub.uvsBounds.bytes, sub.uvsBounds.position, sub.uvsBounds.length);
			}

			if ( sub.colorsBounds ) {
				dsub.colorsBounds.seekToEnd();
				dsub.colorsBounds.length += sub.colorsBounds.length;
				dsub.colorsBounds.bytes.writeBytes(sub.colorsBounds.bytes, sub.colorsBounds.position, sub.colorsBounds.length);
			}

			var bi : ByteArray;
			var dbi : ByteArray;
			

			if ( dsub.indicesBounds && sub.indicesBounds ) {
				
				if( sub.indicesBounds == null ) {
					trace( "awd.MergeGeoms - appendSubGeom -- " );
					trace( "	source : ", source.mesh.name );
					trace( "	dest   : ", dest.mesh.name );
				}
				
				numIndices = sub.indicesBounds.length >> 1;
				dsub.indicesBounds.seekToEnd();
				sub.indicesBounds.seekToStart();

				bi = sub.indicesBounds.bytes;
				dbi = dsub.indicesBounds.bytes;
				

				i = 0;
				while ( i++ < numIndices ) {
					dbi.writeShort(bi.readUnsignedShort() + indexOffset);
				}
				
				dsub.indicesBounds.length += sub.indicesBounds.length;
			} else {
				
				
				// regular destination but composite source
				// convert dest to composite first
				if( dsub.indicesBounds ) {
					dsub.compositeData = new CompositeData();
					dsub.compositeData.addGroup(dsub.indicesBounds, DEFAULT_COMPOSITE_GROUP );
					dsub.indicesBounds = null;
				}
				
				// composite destination
				var compositeSource : CompositeData = sub.compositeData;
				var compositeDest : CompositeData = dsub.compositeData;

				var gid : uint;
				var destBounds : BytesBounds;
				var srcBounds : BytesBounds;
				// trace( "awd.MergeGeoms - appendSubGeom --compositeSource ", compositeSource);
				// trace( "awd.MergeGeoms - appendSubGeom --compositeDest ", compositeDest);
				// trace( "awd.MergeGeoms - appendSubGeom --s  groupIds ", compositeSource.groupIds);
				// trace( "awd.MergeGeoms - appendSubGeom --d  groupIds ", compositeDest.groupIds);

				if ( compositeSource == null ) {
					gid = DEFAULT_COMPOSITE_GROUP;
					destBounds = compositeDest.getGroup(gid);
					srcBounds = sub.indicesBounds;
					
					
					if ( destBounds == null ) 
					{
						destBounds = new BytesBounds(0, 0, new ByteArray() );
						destBounds.bytes.endian = Endian.LITTLE_ENDIAN;
						compositeDest.addGroup(destBounds, gid);
					} 
					
					
					destBounds.seekToEnd();
					srcBounds.seekToStart();

					bi = srcBounds.bytes;
					dbi = destBounds.bytes;
					

					numIndices = srcBounds.length >> 1;
					i = 0;
					while ( i++ < numIndices ) {
						dbi.writeShort( bi.readUnsignedShort()+ indexOffset);
					}
					
					destBounds.length += srcBounds.length;
					
					
				} else {
					
					for (var j : int = 0; j < compositeSource.groupIds.length; j++) {
						gid = compositeSource.groupIds[j];
						destBounds = compositeDest.getGroup(gid);
						srcBounds = compositeSource.getGroup(gid);

						if ( destBounds == null ) {
							destBounds = new BytesBounds(0, 0, new ByteArray() );
							destBounds.bytes.endian = Endian.LITTLE_ENDIAN;
							compositeDest.addGroup(destBounds, gid);
							//compositeSource.removeGroup(gid);
						} 
						destBounds.seekToEnd();
						srcBounds.seekToStart();

						bi = srcBounds.bytes;
						dbi = destBounds.bytes;

						numIndices = srcBounds.length >> 1;
						i = 0;
						while ( i++ < numIndices ) {
							dbi.writeShort(bi.readUnsignedShort() + indexOffset);
						}
						
						destBounds.length += srcBounds.length;
						
					}
				}
			}
		}

		private function getDestSubgeom(v : Vector.<DataSubGeometry>, ds : DataSubGeometry) : DataSubGeometry {
			var targetDs : DataSubGeometry;
			var len : uint = v.length - 1;
			for (var i : int = len; i > -1; --i) {
				
//				trace( v[i].material.name, "			",ds.material.name )	
//				trace( v[i].material.block.id, "			",ds.material.block.id )	
				if (v[i].material == ds.material) {
					targetDs = v[i];
					return targetDs;
				}
			}

			return null;
		}

		private function collect(meshName : String) : void {
			var ds : DataSubGeometry;
			var geom : Geometry;
			var subgeom : SubGeometry;
			
			
			var c : Container = findContainer( meshName );
			if ( c == null )
				throw new Error("awd.MergeGeoms - collect : unable to find mesh '" + meshName + "'"+findMesh(meshName));
			
			
			if( c is Mesh ) {
				var mesh : Mesh = c as Mesh;
	
				mesh = findMesh(meshName);
				
				if( _meshesFounds.AS3::indexOf( mesh ) == -1 ) { 
					_meshesFounds.AS3::push( mesh );
					geom = mesh.geom;
		
					var sceneTransform : Matrix3D = getSceneTransform(mesh);
					var invertSceneTransform : Matrix3D = sceneTransform.clone();
					invertSceneTransform.invert();
		
					for (var i : int = 0; i < geom.subs.length; i++) {
						subgeom = geom.subs[i];
						ds = new DataSubGeometry();
						ds.subGeomIndex = i;
						ds.subGeometry = subgeom;
						ds.material = subgeom.material || mesh.materials[0];
						ds.transform = mesh.mtx.clone();
						ds.mesh = mesh;
						ds.sceneTransform = sceneTransform.clone();
						ds.invertSceneTransform = invertSceneTransform.clone();
		
						_vectorsSource.AS3::push(ds);
					}
				}
			}
			
			for (i = 0; i < c.childs.length; i++) {
				collect(c.childs[i].name );
			}
			
		}

	}
}

import awd.Material;
import awd.Mesh;
import awd.SubGeometry;
import awd.misc.Matrix3D;

class DataSubGeometry {

	public var subGeomIndex : uint;
	public var subGeometry : SubGeometry;
	public var transform : Matrix3D;
	public var sceneTransform : Matrix3D;
	public var mesh : Mesh;
	public var addSub : Boolean;
	public var material : Material;
	public var invertSceneTransform : Matrix3D;
}
