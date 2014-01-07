import os
import signal
import sys
import time
import libvirt
import libvirt_lxc


def _connect_auth_cb(creds, opaque):
    if len(creds) == 0:
        return 0


AUTH = [[libvirt.VIR_CRED_AUTHNAME,
         libvirt.VIR_CRED_ECHOPROMPT,
         libvirt.VIR_CRED_REALM,
         libvirt.VIR_CRED_PASSPHRASE,
         libvirt.VIR_CRED_NOECHOPROMPT,
         libvirt.VIR_CRED_EXTERNAL],
        _connect_auth_cb,
        None]


def list_all_domains():
    uri = 'lxc:///'
    conn = libvirt.openAuth(uri, AUTH, 0)
    return conn.listAllDomains()


def runcmd(cmd, timeout=2):
    argv = cmd.split()
    try:
        rp, wp = os.pipe()
        pid = os.fork()
        if pid == 0:
            os.close(rp)
            wp = os.fdopen(wp, 'w')
            os.dup2(wp.fileno(), 1)
            os.execv(argv[0], argv)
            os.close(wp)
            os._exit(255)
        else:
            os.close(wp)
            last_time = int(time.time())
            cur_time = int(time.time())
            overtime = True
            while cur_time - last_time < timeout:
                os.waitpid(pid, os.WNOHANG)
                pidfile = "/proc/%s" % pid
                if not os.path.exists(pidfile):
                    overtime = False
                    break
                time.sleep(0.1)
                cur_time = int(time.time())

            if overtime:
                os.kill(pid, signal.SIGKILL)
                os.waitpid(pid, 0)

            rp = os.fdopen(rp)
            ret = rp.read()
            rp.close()

        return ret

    except OSError:
        os._exit(255)


def exec_lxc_command(domain, cmd, timeout=2, flags=0):
    ret = None
    try:
        print "exec_lxc_command begin"
        fdlist = libvirt_lxc.lxcOpenNamespace(domain, flags)
        if fdlist is None:
            return ret
        if libvirt_lxc.lxcEnterNamespace(domain, fdlist, flags) < 0:
            for fd in fdlist:
                os.close(fd)
            return ret

        ret = runcmd(cmd)

        for fd in fdlist:
            os.close(fd)

        print "exec_lxc_command end"
        return ret
    except (libvirt.libvirtError, OSError) as e:
        return None


if __name__ == "__main__":

    print "begin"
    domains = list_all_domains()

    for domain in domains:
        ret = exec_lxc_command(domain, "/bin/df -hl")
        print "result : %s " % ret

    print "over"
