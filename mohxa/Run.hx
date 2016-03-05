package mohxa;

import mohxa.Mohxa;

class Run {

    public var total:Int = 0;
    public var failed:Int = 0;
    public var time:Float = 0.0;
    public var list:Array<Mohxa>;

    public function new(_list:Array<Mohxa>, _do_run:Bool=true) {

        list = _list;

        if(_do_run) run();

    } //new

    public function run() {

        for(item in list) run_one(item);

    } //run

    public function run_one<T:Mohxa>(instance:T) {

        instance.run();

        total += instance.total;
        failed += instance.failed;
        time += instance.total_time;

    } //run_one

} //Run
