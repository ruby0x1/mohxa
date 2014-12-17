package mohxa;

    //Simple test runner with simple logging, nested tests, and more
    //MIT License, based on https://github.com/visionmedia/mocha
    //https://github.com/underscorediscovery/mohxa

typedef MohxaHandler = Void->Void;


class Mohxa {

    static var tfailed = 0;
    static var ttotal = 0;
    static var ttime = 0.0;

    public var failed : Int = 0;
    public var total : Int = 0;
    public var total_time : Float = 0;

    public var current_depth : Int = 0;
    public var current_set : Mohxa.MohxaTestSet;

    var test_sets : Mohxa.MohxaTestSet;
    var failures : Map<Int, MohxaFailure>;

    //logging

        public static var use_colors : Bool = true;

        static var symbols : { ok:String, err:String, dot:String };
        static var system_name : String = '';
        static var use_specialchars : Bool = true;

// Class specifics

    public function new() {

        failures = new Map();

        #if js
            system_name = "Web";
        #else
            system_name = Sys.systemName();
        #end

            //control coloring etc by platform
        setup_logging();

            //create the base test set
            //to add subsequent tests to
        create_root_set();

    } //new

    public function run() {

        _log('\n');

        failed = 0;
        total_time = haxe.Timer.stamp();

            test_sets._traverse();

        total_time = (haxe.Timer.stamp() - total_time) * 1000;
        ttime += total_time;
        total_time = fixed(total_time);

        _log('\n');

        if(failed > 0) {
            _log( error() + ' ' + failed + ' of ' + total + ' failed  (' + dim() + total_time + 'ms' + reset() + ') \n' );
                //display all failures
            var _f : Int = 0;
            for(failure in failures) {
                _log( tabs(1) + red() + _f  + ') ' + reset() + failure.test.name  );
                _log( tabs(2) + error() + dim() + ' because ' + reset() + red() + failure.details + reset() );
                _log( dim(), true );
                failure.display(3);
                doreset();
                _f++;
            }
        } else {
            _log( ok() + green() + ' ' + total + ' tests completed. ' +reset()+ dim() + ' (' + total_time + 'ms' + ')' + reset());
        }

        _log('\n');

        doreset();

    } //run

//Helpers

    @:noCompletion
    public function onfail( failure:MohxaFailure ) {

        _log( tabs(failure.test.set.depth+3) + error() + red() + ' fail (' + failed + ')'  + reset());
        failures.set( failed, failure );
        failed++;
        tfailed++;

    } //onfail

    @:noCompletion
    public function onrun(t:MohxaTest) {

        _log( tabs(t.set.depth+2) + dim() + dot() + ' ' + t.name +  reset() );

    } //onrun

    @:noCompletion
    public function onpass(t:MohxaTest, runtime:Float ) {

        var _time = '';

        if(runtime > 50 && runtime < 100) {
            _time = reset() + yellow() + ' (' + runtime + 'ms)';
        } else if(runtime > 100) {
            _time =  reset() + red() + ' (' + runtime + 'ms)';
        }

        _log( tabs(t.set.depth+3) + ok() + green() + ' pass' + _time + reset() );

    } //onpass

//API


    @:generic
    public function log<T>( e:T ) {

        var _parsed = strip_mohxa_calls( haxe.CallStack.callStack() );

        _log( tabs(current_depth+2) + dim() + _parsed[0] + ': ' + e + reset() );

    } //log

    public function it( desc:String, handler:MohxaHandler ) {

        total++;
        ttotal++;
        current_set.add_test( new MohxaTest(this, desc, handler) );

    } //it

    public function describe( name:String, handler:MohxaHandler ) {

        if(current_set != null) {
            current_set.add_group( new MohxaTestSet(this, name, handler) );
        }

    } //describe


    public function before( handler:MohxaHandler ) {

        current_set.before = handler;

    } //before

    public function after( handler:MohxaHandler ) {

        current_set.after = handler;

    } //after

    public function beforeEach( handler:MohxaHandler ) {

        current_set.beforeEach = handler;

    } //beforeEach

    public function afterEach( handler:MohxaHandler ) {

        current_set.afterEach = handler;

    } //afterEach

    @:generic
    public function equal<T>(value:T, expected:T, ?tag:String = '') {

        if( value != expected ) {
            _logv( tabs(current_set.depth+4) + error() + dim() + ' ' + ((tag.length>0) ? tag : '') + ' ' + reset() + red() + (value + ' != ' + expected) + reset() );
            throw (value + ' != ' + expected) + '  ' + ((tag.length>0) ? '('+tag+')' : '');
        } else {
            _logv( tabs(current_set.depth+4) + ok() + dim() + ' ' + ((tag.length>0) ? tag : '') + reset() );  //' ' +reset() + green() + (value + ' == ' + expected) +
        }
    }

    @:generic
    public function notequal<T>(value:T, unexpected:T, ?tag:String = '') {
        if( value == unexpected ) {
            _logv( tabs(current_set.depth+4) + error() + dim() + ' ' + ((tag.length>0) ? tag : '') + ' ' +reset() + red() + (value + ' == ' + unexpected) + reset() );
            throw (value + ' == ' + unexpected) + '  ' + ((tag.length>0) ? '('+tag+')' : '');
        } else {
            _logv( tabs(current_set.depth+4) + ok() + dim() + ' ' + ((tag.length>0) ? tag : '') + reset() );
        }
    }

    static var epsilon = 0.0001;

    public function equalfloat(value:Float, expected:Float, ?tag:String = '') {
        if(!(Math.abs(expected - value) < epsilon)) {
            _logv( tabs(current_set.depth+4) + error() + dim() + ' ' + ((tag.length>0) ? tag : '') + ' ' + reset() + red() + (value + ' != ' + expected) + reset() );
            throw (value + ' == ' + expected) + ' (float) ' + ((tag.length>0) ? '('+tag+')' : '');
        } else {
            _logv( tabs(current_set.depth+4) + ok() + dim() + ' ' + ((tag.length>0) ? tag : '') + reset() );
        }
    }

    public function equalint(value:Int, expected:Int, ?tag:String = '') {
        if(Std.int(value) != Std.int(expected)) {
            _logv( tabs(current_set.depth+4) + error() + dim() + ' ' + ((tag.length>0) ? tag : '') + ' ' + reset() + red() + (value + ' != ' + expected) + reset() );
            throw (value + ' == ' + expected) + ' (int) ' + ((tag.length>0) ? '('+tag+')' : '');
        } else {
            _logv( tabs(current_set.depth+4) + ok() + dim() + ' ' + ((tag.length>0) ? tag : '') + reset() );
        }
    }

//Internal

    function create_root_set() {

        current_set = test_sets = new Mohxa.MohxaTestSet(this, '', null);

        test_sets.init();

    } //create_root_set

//Internal API helpers

    public static var verbose = false;
    @:noCompletion
    public static function _logv(v:Dynamic, ?print:Bool = false) {
        if(verbose) _log(v, print);
    }

    @:noCompletion
    public static function _log(v:Dynamic, ?print:Bool = false) {

        #if (cpp || neko)
            if(!print) {
                Sys.println(v);
            } else {
                Sys.print(v);
            }
        #elseif js
            untyped __js__('console.log(v)');
        #else
            trace(v);
        #end

    } //_log

    @:noCompletion
    public function strip_mohxa_calls(list:Array<haxe.CallStack.StackItem>) : Array<String> {

        var results = [];

        for(item in list) {
            var _params = item.getParameters();
            if( Std.string(_params[1]).indexOf('Mohxa.hx') == -1) {
                results.push( ' at ' + _params[1] + ':' + _params[2] );
            }
        }

        return results;

    } //strip_mohxa_calls

    @:noCompletion
    public function tabs(t:Int, tabwidth:Int=2) {

        var s = '';
        for(i in 0 ... (t*tabwidth)) {
            s+=' ';
        }

        return s;

    } //tabs

    public static function finish() {
        ttime = fixed(ttime);
        _log('Mohxa finished with :');
        if(tfailed > 0) {
            _log( error() + ' ' + tfailed + ' of ' + ttotal + ' failed  (' + dim() + ttime + 'ms' + reset() + ') \n' );
        } else {
            _log( ok() + green() + ' ' + ttotal + ' tests completed. ' +reset()+ dim() + ' (' + ttime + 'ms' + ')' + reset());
        }
    }

    @:noCompletion
    public static function fixed(v:Float, p:Int=3) {
        var n = Math.pow(10,p);
        return (Std.int(v*n) / n);
    }

    function setup_logging() {

        if(use_colors) {
            switch(system_name) {
                case "Web", "Windows": use_colors = false;
                case _: use_colors = true;
            }
        }

        if(!use_specialchars) {
            symbols = { ok: 'ok', err: '!!', dot: '>' };
        } else {
            symbols = { ok: '✓', err: '✖', dot: '▸' };
        }

    } //setup_logging

    static function doreset()  { _log(reset(), true); }
    static function dot()      { return symbols.dot; }
    static function reset()    { return !use_colors ? '' : "\033[0m";  }
    static function yellow()   { return !use_colors ? '' : "\033[93m"; }
    static function green()    { return !use_colors ? '' : "\033[92m"; }
    static function red()      { return !use_colors ? '' : "\033[91m"; }
    static function bright()   { return !use_colors ? '' : "\033[1m";  }
    static function dim()      { return !use_colors ? '' : "\033[2m";  }
    static function ok()       { return !use_colors ? symbols.ok : "\033[92m"+symbols.ok+"\033[0m"; }
    static function error()    { return !use_colors ? symbols.err : "\033[91m"+symbols.err+"\033[0m"; }

} //Mohxa

class MohxaRunnable {

    public var runner : Mohxa;
    public var name : String;
    public var run : MohxaHandler;

    public var before : MohxaHandler;
    public var after : MohxaHandler;
    public var beforeEach : MohxaHandler;
    public var afterEach : MohxaHandler;

    public function new(_runner:Mohxa, _name:String, _run:MohxaHandler) {

        runner = _runner; name = _name; run = _run;
        init();

    } //new

    public function init() {

    } //init

} //MohxaRunnable

class MohxaTest extends MohxaRunnable {
        //test cases stored in this test
    public var set : MohxaTestSet;

} //MohxaTest

class MohxaFailure {

    public var details : String = 'Unknown';
    public var stack : Array<haxe.CallStack.StackItem>;
    public var test : MohxaTest;

    public function new(_det:String, _test:MohxaTest) {

        details = _det;
        test = _test;
        stack = haxe.CallStack.exceptionStack();

    } //new

    public function display(t:Int) {

        var _parsed = test.runner.strip_mohxa_calls(stack);
        for(item in _parsed) {
            Mohxa._log( test.runner.tabs(t) + item );
        }

    } //display

} //MohxaFailure

class MohxaTestSet extends MohxaRunnable {

    public var tests : Array<MohxaTest>;
    public var groups : Array<MohxaTestSet>;
    public var depth : Int = 0;

    var group_index : Int = 0;

    public function add_group( _group:MohxaTestSet ) {

        _group.depth = depth+1;
        groups.push( _group );
        // trace( runner.tabs(depth) + ' > adding group ' + _group.name + ' at ' + (depth+1));

    } //add_group

    public function add_test( _test:MohxaTest ) {

        _test.set = this;
        tests.push( _test );
        // trace( runner.tabs(depth) + ' > adding test ' + _test.name );

    } //add_test

    public override function init() {

        tests = [];
        groups = [];

    } //init

    public function _traverse() {

        if( before != null ) {
            before();
        }

        for(test in tests) {

            runner.current_depth = test.set.depth+1;

            if( beforeEach != null ) beforeEach();

            try {
                runner.onrun(test);

                var test_time = haxe.Timer.stamp();

                    test.run();

                test_time = (haxe.Timer.stamp() - test_time) * 1000;
                test_time = Mohxa.fixed(test_time);

                    runner.onpass(test, test_time);

            } catch(e:Dynamic) {

                runner.onfail( new MohxaFailure(e,test) );

            } //catch

            if( afterEach != null ) afterEach();
        } //for each test

        for(group in groups) {

            runner.current_depth = depth;
            runner.current_set = group;

            Mohxa._log(runner.tabs(depth) + group.name );

            group.run();
            group._traverse();

        } //for each group

        runner.current_depth = 0;

        if( after != null ) {
            after();
        }

    } //traverse

} //MohxaTestSet



