package awd {


	/**
	 * @author Pierre Lepers
	 * awd.Geometry
	 */
	public class SubGeometry extends NamedAsset {

		
		public var verticesBounds : BytesBounds;
		public var indicesBounds : BytesBounds;
		public var uvsBounds : BytesBounds;
		public var normalsBounds : BytesBounds;
		public var colorsBounds : BytesBounds;
//		public var compositeBounds : BytesBounds;
		public var compositeData : CompositeData;
		public var material : Material;

	}
}
