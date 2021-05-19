using Base.Threads

some_function_call_1() = begin
    println("some_function_call_1, ", Threads.threadid())
    sleep(rand())
end
some_function_call_2() = begin
    println("some_function_call_2, ", Threads.threadid())
    sleep(rand())
end
do_main_work(iter) = begin
    println("do_main_work, $(iter), ", Threads.threadid())
    sleep(rand())
end

some_task = Threads.@spawn begin
    some_function_call_1()
    some_function_call_2()
end

for rep in 1:3
    Threads.@threads for iter in 1:4
        do_main_work(iter)
    end
    global some_task
    wait(some_task)
    some_task = Threads.@spawn begin
        some_function_call_1()
        some_function_call_2()
    end
end

wait(some_task)
