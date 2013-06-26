


package awd.cmd {

	import awd.Dump;
	import avmplus.FileSystem;
	import avmplus.System;

	import flash.utils.ByteArray;
	
	public class dump_awd {
			
		private var cl : CommandLine;
		
		public function dump_awd(args : Array) {
			
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
			var merge : Dump = new Dump( awdIn );
			
		}
		
		private function printHelp() : void {
			
			var nl : String = "\n";
			
			var help : String = "";
			
			help += "dump_awd"+nl;
			help += "dump awd content"+nl;
//			help += "author Pierre Lepers (pierre[dot]lepers[at]gmail[dot]com)"+nl;
//			help += "powered by RedTamarin"+nl;
//			help += "version 1.0"+nl;
//			help += "usage : awd_little_endian "+nl;
//			
			help += " -i <awdfile> input awd file"+nl;
			
			trace( help );
		}
	}
	
}



import avmplus.System;

import awd.cmd.dump_awd;

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


	private function handleHelp( args : Array ) : void {
		_help = true;
	}

	

	private function _init() : void {
		_argHandlers = new Dictionary();
		
		_argHandlers[ "-i" ] = handleIn;
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
include "../Dump.as"



var main : dump_awd = new dump_awd( System.argv );
