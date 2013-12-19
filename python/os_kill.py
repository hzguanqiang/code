import os
import signal
import sys
import time


def runcmd(cmd, timeout=5):
    ret = -2
    argv = cmd.split()
    pid = os.fork()
    if pid == 0:
        os.execv(argv[0], argv)
        sys.exit(1)
    else:
        os.waitpid(pid, 0)
        ret = 0
        return ret


def handle_sigchld(signum, frame):
    try:
        pid, status = os.waitpid(-1, 0)
    except OSError:
        pass


def test(cmd):
    os.system("echo `date` test begin")
    pid = os.fork()
    if pid == 0:
        os.system("echo `date` test ------enter child")
        runcmd(cmd)
        os.system("echo `date` test ------leave child")
        sys.exit(1)
    else:
        signal.signal(signal.SIGCHLD, handle_sigchld)
        print "pid : %s" % pid
        timeout = 50
        runtime = 0
        overtime = True
        while runtime < timeout:
            time.sleep(0.1)
            runtime += 0.1
            pidfile = "/proc/%s" % pid
            if not os.path.exists(pidfile):
                print "pidfile %s  not exist, pid have exited" % pidfile
                overtime = False
                break
        if overtime:
            print "50s timeout and kill %s" % pid
            os.kill(pid, signal.SIGKILL)

    os.system("echo `date` test end")


if __name__ == "__main__":
    print "In main"
    ret = test("/bin/sleep 100")
