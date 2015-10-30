import os
import libvirt


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
    uri = 'qemu:///system'
    conn = libvirt.openAuth(uri, AUTH, 0)
    return conn.listAllDomains()


def set_blkdeviotune(domain, disk, params):
    try:
        print "begin to set blkiotune"
        ret = domain.setBlockIoTune(disk, params)
        return ret
    except (libvirt.libvirtError, OSError) as e:
        return None


if __name__ == "__main__":

    print "begin"
    domains = list_all_domains()
    params = {"read_iops_sec": 9999}

    for domain in domains:
        ret = set_blkdeviotune(domain, "vda", params)
        print "result : %s " % ret

    print "over"
