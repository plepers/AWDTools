package awd {

	import avmplus.FileSystem;
	import avmplus.System;

	import flash.utils.ByteArray;
	
	public class awd_little_endian {
			
		private var cl : CommandLine;
		
		public function awd_little_endian(args : Array) {
			
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
			var tol : ToLittleEndian = new ToLittleEndian( awdIn );
			var result : ByteArray = tol.convert();
			
			if( result != null )
				FileSystem.writeByteArray( cl.output, result );
			else {
				trace( "input already little endian" );
				if( cl.output != cl.input ) 
					FileSystem.move(cl.input, cl.output );
//					FileSystem.writeByteArray( cl.output, awdIn );
			}
			
			trace( "awd_little_endian done");
		}
		
		private function printHelp() : void {
			
			var nl : String = "\n";
			
			var help : String = "";
			
			help += "awd_little_endian"+nl;
			help += "convert awd to little endian"+nl;
			help += "author Pierre Lepers (pierre[dot]lepers[at]gmail[dot]com)"+nl;
			help += "powered by RedTamarin"+nl;
			help += "version 1.0"+nl;
			help += "usage : awd_little_endian "+nl;
			
			help += " -i <awdfile> input awd file"+nl;
			help += " -o <filename> : output little endian file"+nl;
			
			trace( help );
		}
	}
	
}



import avmplus.System;

import awd.awd_little_endian;

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

	private function handleHelp( args : Array ) : void {
		_help = true;
	}

	

	private function _init() : void {
		_argHandlers = new Dictionary();
		
		_argHandlers[ "-i" ] = handleIn;
		_argHandlers[ "-o" ] = handleOutput;
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
	

	
}


include "ToLittleEndian.as"


var main : awd_little_endian = new awd_little_endian( System.argv );
