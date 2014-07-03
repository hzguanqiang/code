from multiprocessing import Process, Queue


def my_function(q, x):
    d = x + 1000
#    q.put(d)
    q.put("hello world \n hello test")

if __name__ == '__main__':
    queue = Queue()
    p = Process(target=my_function, args=(queue, 1))
    p.start()
    p.join()  # this blocks until the process terminates
    result = queue.get()
    print result
