


package awd.cmd {

	import awd.MergeGeoms;
	import avmplus.FileSystem;
	import avmplus.System;

	import flash.utils.ByteArray;
	
	public class merge_geoms {
			
		private var cl : CommandLine;
		
		public function merge_geoms(args : Array) {
			
			cl = new CommandLine( args );
			
			if( cl.isEmpty() ) {
				printHelp();
				System.exit( 0 );
			}
			
			_run();
			
			System.exit( 0 );
			
		}

		private function _run() : void {
			
			var awdIn : ByteArray = FileSystem.readByteArray( cl.input );
			var merge : MergeGeoms= new MergeGeoms( awdIn, cl.receiver, cl.meshes );
			
			FileSystem.writeByteArray( cl.output, merge.recompose() );
			trace( cl.output );
			trace( "merge_geoms done");
		}
		
		private function printHelp() : void {
			
			var nl : String = "\n";
			
			var help : String = "";
			
			help += "merge_geoms"+nl;
//			help += "convert awd to little endian"+nl;
//			help += "author Pierre Lepers (pierre[dot]lepers[at]gmail[dot]com)"+nl;
//			help += "powered by RedTamarin"+nl;
//			help += "version 1.0"+nl;
//			help += "usage : awd_little_endian "+nl;
//			
			help += " -i <awdfile> input awd file"+nl;
			help += " -o <filename> : output little endian file"+nl;
			help += " -r <meshname> : mesh to merge in"+nl;
			help += " -m <meshname> repetable : meshes to merge to"+nl;
			
			trace( help );
		}
	}
	
}



import avmplus.System;

import awd.cmd.merge_geoms;

import flash.utils.Dictionary;

class CommandLine {


	public function isEmpty() : Boolean {
		return _empty;
	}

	
	public function CommandLine( arguments : Array ) {
		_init();
		_build(arguments);
	}

	private var _output : String;
	private var _input : String;
	private var _receiver : String;
	private var _meshes : Vector.<String>;
	private var _help : Boolean;
	
	private function _build(arguments : Array) : void {
		
		
		_empty = arguments.length == 0;
		var arg : String;
		while( arguments.length > 0 ) {
			arg = arguments.shift();
			var handler : Function = _argHandlers[ arg ];
			if( handler == undefined )
				throw new Error(arg + " is not a valid argument." + HELP);
				
			handler(arguments);
		}
	}
	

	
	private function handleIn( args : Array ) : void {
		_input = formatPath( args.shift() );
	}

	private function handleOutput( args : Array ) : void {
		if( _output != null )
			throw new Error("-o / -output argument cannot be define twice." + HELP);
		_output = args.shift();
	}
	
	private function handleReceiver( args : Array ) : void {
		_receiver = args.shift();
	}

	private function handleMeshes( args : Array ) : void {
		if( _meshes == null )
			_meshes = new Vector.<String>();
		
		var m : String = args.shift();
		if( _meshes.AS3::indexOf( m ) > -1 ) return;
		_meshes.AS3::push(m);
	}

	private function handleHelp( args : Array ) : void {
		_help = true;
	}

	

	private function _init() : void {
		_argHandlers = new Dictionary();
		
		_argHandlers[ "-i" ] = handleIn;
		_argHandlers[ "-o" ] = handleOutput;
		_argHandlers[ "-r" ] = handleReceiver;
		_argHandlers[ "-m" ] = handleMeshes;
		_argHandlers[ "-help" ] = handleHelp;
	}
	
	private function formatPath( str : String ) : String {
		/*FDT_IGNORE*/
		return str.AS3::replace( /\\/g, "/" );
		/*FDT_IGNORE*/;
		return str;
	}
	
	private var _empty : Boolean = true;

	private var _argHandlers : Dictionary;


	private static const HELP : String = " -help for more infos.";
	

	public function get output() : String {
		return _output || _input;
	}

	public function get input() : String {
		return _input;
	}
	
	public function get help() : Boolean {
		return _help;
	}

	public function get receiver() : String {
		return _receiver;
	}

	public function get meshes() : Vector.<String> {
		return _meshes;
	}
	

	
}



include "../BaseParser.as"
include "../MergeGeoms.as"



var main : merge_geoms = new merge_geoms( System.argv );
