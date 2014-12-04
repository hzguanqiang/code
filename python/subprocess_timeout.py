import subprocess
import os
import time
import sys
import signal


class Timeout(Exception):
    print "run timeout"


def run(command, timeout=10):
    proc = subprocess.Popen(command, bufsize=0,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            preexec_fn=os.setsid)
    poll_seconds = .250
    deadline = time.time() + timeout
    while time.time() < deadline and proc.poll() == None:
        time.sleep(poll_seconds)

    if proc.poll() == None:
        if float(sys.version[:3]) >= 2.6:
            import pdb; pdb.set_trace() ### XXX BREAKPOINT
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            proc.terminate()
            proc.kill()
            print "run timeout"

    stdout, stderr = proc.communicate()
    return stdout, stderr, proc.returncode


if __name__ == "__main__":
#    print run(["ls", "-l"])
#    print run(["find", "/"], timeout=3) #should timeout
    print run(["sudo", "ping", "www.baidu.com"], timeout=3)
