package mohxa;

    //Simple test runner with simple logging, nested tests, and more
    //MIT License, based on https://github.com/visionmedia/mocha
    //https://github.com/underscorediscovery/mohxa

typedef MohxaHandler = Void->Void;


@:allow(mohxa.MohxaTestSet)
@:allow(mohxa.MohxaRunnable)
@:allow(mohxa.MohxaFailure)
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
            use_specialchars = false;
        #elseif flash
            system_name = "flash";
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

        i('\n');

        failed = 0;
        total_time = haxe.Timer.stamp();

        i( t(current_depth+1) + '$dot running ... $reset\n');

            test_sets._traverse();

        total_time = (haxe.Timer.stamp() - total_time) * 1000;
        ttime += total_time;
        total_time = fixed(total_time);

        i('\n');

        if(failed > 0) {
            i( '$error $failed of $total failed ($dim ${total_time}ms $reset) \n' );

                //display all failures
            var _f : Int = 0;

            for(failure in failures) {

                i( t(current_depth+3) + '$red $_f ) reset ${failure.test.name}');
                i( t(current_depth+4) + '$error $dim because $reset $red ${failure.details} $reset');
                i( dim, true );

                failure.display(current_depth+2);

                doreset();
                _f++;
            }
        } else {
            i( t(current_depth+2) + '$ok $green $total tests completed. $reset $dim (${total_time}ms) $reset');
        }

        i('\n');

        doreset();

    } //run

//Helpers

    function onfail( failure:MohxaFailure ) {

        i( t(failure.test.set.depth+5) + '$error $red fail ($failed) $reset' );

        failures.set( failed, failure );

        failed++;
        tfailed++;

    } //onfail

    function onrun(test:MohxaTest) {

        i( t(test.set.depth+4) + '$dim$dot ${test.name} $reset');

    } //onrun

    function onpass(test:MohxaTest, runtime:Float ) {

        var _time = '';

        if(runtime > 50 && runtime < 100) {
            _time = '$reset $yellow (${runtime}ms)';
        } else if(runtime > 100) {
            _time =  '$reset $red (${runtime}ms)';
        }

        i( t(test.set.depth+5) + '$ok$green pass $_time $reset' );

    } //onpass

//API


    #if !mohxa_no_generic @:generic #end
    public function log<T>( e:T ) {

        var _parsed = strip_mohxa_calls( haxe.CallStack.callStack() );

        i( t(current_depth+6) + '$dim ${_parsed[0]} : $e $reset' );

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

    function t0(_t) return (_t.length>0) ? _t : '';
    function t1(_t) return (_t.length>0) ? '($_t)' : '';
    #if !mohxa_no_generic @:generic #end function e0<T>(_f,_v:T,_e:T,_t,_o) return t(current_set.depth+6) + '$error$dim ($_f) ${t0(_t)} $reset $red ($_v $_o $_e) $reset';
    #if !mohxa_no_generic @:generic #end function e1<T>(_f,_v:T,_e:T,_t,_o) return '($_f) ($_v $_o $_e)  ${t1(_t)}';
    #if !mohxa_no_generic @:generic #end function p0<T>(_f,_v:T,_e:T,_t,_o) return t(current_set.depth+6) + '$ok$dim ${t0(_t)} $reset';

    #if !mohxa_no_generic @:generic #end
    public function equal<T>(value:T, expected:T, ?tag:String = '') {

        if( value != expected ) {
            v( e0('equal', value, expected, tag, '!=') );
            throw e1('equal', value, expected, tag, '!=');
        } else {
            v( p0('equal', value, expected, tag, '==') );
        }
    }

    #if !mohxa_no_generic @:generic #end
    public function notequal<T>(value:T, unexpected:T, ?tag:String = '') {
        if( value == unexpected ) {
            v( e0('notequal', value, unexpected, tag, '==') );
            throw e1('notequal', value, unexpected, tag, '==');
        } else {
            v( p0('notequal', value, unexpected, tag, '!=') );
        }
    }

    public function equalfloat(value:Float, expected:Float, ?tag:String = '', epsilon:Float=0.00001) {
        if(!(Math.abs(expected - value) < epsilon)) {
            v( e0('equalfloat', value, expected, tag, '!=') );
            throw e1('equalfloat', value, expected, tag, '!=');
        } else {
            v( p0('equalfloat', value, expected, tag, '==') );
        }
    }

    public function equalint(value:Int, expected:Int, ?tag:String = '') {
        if(Std.int(value) != Std.int(expected)) {
            v( e0('equalint', value, expected, tag, '!=') );
            throw e1('equalint', value, expected, tag, '!=');
        } else {
            v( p0('equalint', value, expected, tag, '==') );
        }
    }

    #if !mohxa_no_generic @:generic #end
    public function equalarray<T>(value:Array<T>, expected:Array<T>, ?tag:String = '') {
        if(value.length != expected.length) {
            v( e0('equalarray', value, expected, tag, '!=') );
            throw e1('equalarray', value, expected, tag, '!=');
        }
        var f = true;
        for(i in 0 ... value.length) {
            var a = value[i];
            var b = expected[i];
            
            f = f && (a == b);
        }
    } //equalarray

//Internal

    function create_root_set() {

        current_set = test_sets = new Mohxa.MohxaTestSet(this, '', null);

        test_sets.init();

    } //create_root_set

//Internal API helpers

    public static var verbose = false;
    static function v(v:Dynamic, ?print:Bool = false) {
        if(verbose) i(v, print);
    }

    static function i(v:Dynamic, ?print:Bool = false) {

        #if sys
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

    function strip_mohxa_calls(list:Array<haxe.CallStack.StackItem>) : Array<String> {

        var results = [];

        for(item in list) {
            var _params = item.getParameters();
            var _p1 = Std.string(_params[1]);
            var has_Moxha_hx = _p1.indexOf('Mohxa.hx') != -1;
            var has_Moxha_pack = _p1.indexOf('mohxa.Mohxa') != -1;
            if(!has_Moxha_pack && !has_Moxha_hx) {
                results.push( ' at ' + _params[1] + ':' + _params[2] );
            }
        }

        return results;

    } //strip_mohxa_calls

        //t = tab count, w = width
    function t(c:Int, w:Int=2) {

        var s = '';
        for(i in 0 ... (c*w)) {
            s+=' ';
        }

        return s;

    } //tabs

    public static function finish() {
        ttime = fixed(ttime);
        i('Mohxa finished with :');
        if(tfailed > 0) {
            i( '$error $tfailed of $ttotal failed $dim(${ttime}ms ) $reset\n' );
        } else {
            i( '$ok $green $ttotal tests completed. $dim(${ttime}ms) $reset');
        }
    }

    static function fixed(v:Float, p:Int=3) {
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

    static function doreset()  { i(reset, true); }

    static var dot      (get,null) : String;
    static var ok       (get,null) : String;
    static var error    (get,null) : String;

    static var reset    (get,null) : String;
    static var yellow   (get,null) : String;
    static var green    (get,null) : String;
    static var red      (get,null) : String;
    static var bright   (get,null) : String;
    static var dim      (get,null) : String;

    static function get_dot()       { return symbols.dot; }
    static function get_ok()        { return !use_colors ? symbols.ok : "\033[92m"+symbols.ok+"\033[0m"; }
    static function get_error()     { return !use_colors ? symbols.err : "\033[91m"+symbols.err+"\033[0m"; }

    static function get_reset()    { return !use_colors ? '' : "\033[0m";  }
    static function get_yellow()   { return !use_colors ? '' : "\033[93m"; }
    static function get_green()    { return !use_colors ? '' : "\033[92m"; }
    static function get_red()      { return !use_colors ? '' : "\033[91m"; }
    static function get_bright()   { return !use_colors ? '' : "\033[1m";  }
    static function get_dim()      { return !use_colors ? '' : "\033[2m";  }

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

    public function display(tabs:Int) {

        var _parsed = test.runner.strip_mohxa_calls(stack);
        for(item in _parsed) {
            Mohxa.i( test.runner.t(tabs) + item );
        }

    } //display

} //MohxaFailure

@:allow(Mohxa)
class MohxaTestSet extends MohxaRunnable {

    public var tests : Array<MohxaTest>;
    public var groups : Array<MohxaTestSet>;
    public var depth : Int = 0;

    var group_index : Int = 0;

    public function add_group( _group:MohxaTestSet ) {

        _group.depth = depth+1;
        groups.push( _group );
        // trace( runner.t(depth) + ' > adding group ' + _group.name + ' at ' + (depth+1));

    } //add_group

    public function add_test( _test:MohxaTest ) {

        _test.set = this;
        tests.push( _test );
        // trace( runner.t(depth) + ' > adding test ' + _test.name );

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

            Mohxa.i(runner.t(depth+4) + '${Mohxa.dot} ${group.name}' );

            group.run();
            group._traverse();

        } //for each group

        runner.current_depth = 0;

        if( after != null ) {
            after();
        }

    } //traverse

} //MohxaTestSet



