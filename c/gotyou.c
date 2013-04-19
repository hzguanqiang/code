/*
 *  * check if a linux system running on a virtual machine (vmware/xen hvm/kvm)
 *   * written by http://www.vpsee.com
 *    */

#include <stdio.h>
#include <string.h>

#define HYPERVISOR_INFO 0x40000000

#define CPUID(idx, eax, ebx, ecx, edx) \
        asm volatile ( \
                       "test %1,%1 ; jz 1f ; ud2a ; .ascii \"xen\" ; 1: cpuid" \
                       : "=b" (*ebx), "=a" (*eax), "=c" (*ecx), "=d" (*edx) \
                       : "0" (idx) );

int main(void)
{
        unsigned int eax, ebx, ecx, edx;
        char string[13];

        CPUID(HYPERVISOR_INFO, &eax, &ebx, &ecx, &edx);
        *(unsigned int *)(string+0) = ebx;
        *(unsigned int *)(string+4) = ecx;
        *(unsigned int *)(string+8) = edx;

        string[12] = 0;
        if (strncmp(string, "XenVMMXenVMM", 12) == 0) {
            printf("xen hvm\n");
        } else if (strncmp(string, "VMwareVMware", 12) == 0) {
            printf("vmware\n");
        } else if (strncmp(string, "KVMKVMKVM", 12) == 0) {
            printf("kvm\n");
        } else
            printf("bare hardware\n");

        return 0;
} 
