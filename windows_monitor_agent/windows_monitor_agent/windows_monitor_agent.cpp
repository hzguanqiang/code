// windows_monitor_agent.cpp : 定义控制台应用程序的入口点。
//
#define WIN32_LEAN_AND_MEAN 1
#include "stdafx.h"

#include <fcntl.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <wchar.h>
#include <pdh.h>
#include <pdhmsg.h>
#include <malloc.h>

#pragma comment(lib, "pdh.lib")

CONST PWSTR SYSTEM_HANDLE_COUNT_CPATH = L"\\Process(_Total)\\Handle Count";
CONST PWSTR SYSTEM_THREAD_COUNT_CPATH = L"\\System\\Threads";
CONST PWSTR SYSTEM_PROCESS_COUNT_CPATH = L"\\System\\Processes";

CONST PWSTR CPUUSAGE_CPATH = L"\\Processor(_Total)\\% Processor Time";
CONST PWSTR MEM_AVAIL_CPATH = L"\\Memory\\Available MBytes";

CONST PWSTR DISK_READ_BPS_CPATH = L"\\PhysicalDisk(_Total)\\Disk Read Bytes/sec";
CONST PWSTR DISK_WRITE_BPS_CPATH = L"\\PhysicalDisk(_Total)\\Disk Write Bytes/sec";
CONST PWSTR DISK_READ_IOPS_CPATH = L"\\PhysicalDisk(_Total)\\Disk Reads/sec";
CONST PWSTR DISK_WRITE_IOPS_CPATH = L"\\PhysicalDisk(_Total)\\Disk Writes/sec";

CONST PWSTR NETWORK_BPS_RECEIVED_CPATH = L"\\Network Interface(*)\\Bytes Received/sec";
CONST PWSTR NETWORK_BPS_SENT_CPATH = L"\\Network Interface(*)\\Bytes Sent/sec";

CONST ULONG SAMPLE_INTERVAL_MS = 10000;
//CONST ULONG SAMPLE_INTERVAL_MS = 1000;
//CONST PSTR PERF_FILE = "c:\\windows\\qemu-ga\\perf.txt";
CONST PSTR PERF_FILE = "perf.txt";

void wmain(int argc, WCHAR **argv)
{
	HQUERY hQuery = NULL;
	PDH_STATUS pdhStatus;

	HCOUNTER hcSystemHandleCount, hcSystemThreadCount, hcSystemProcessCount;
	HCOUNTER hcCpuUsage, hcMemAvail;
	HCOUNTER hcDiskReadBps, hcDiskWriteBps, hcDiskReadIops, hcDiskWriteIops;
	HCOUNTER hcNetworkBpsReceived, hcNetworkBpsSent;

	DWORD dwCount;
	PDH_FMT_COUNTERVALUE counterVal;

	MEMORYSTATUSEX memInfo;
	memInfo.dwLength = sizeof(MEMORYSTATUSEX);
	GlobalMemoryStatusEx(&memInfo);
	DWORDLONG totalPhysMem = memInfo.ullTotalPhys / 1024 / 1024;

	// Open a query object.
	pdhStatus = PdhOpenQuery(NULL, 0, &hQuery);

	if (pdhStatus != ERROR_SUCCESS)
	{
		wprintf(L"PdhOpenQuery failed with 0x%x\n", pdhStatus);
		goto cleanup;
	}

	// Add counters
	PdhAddCounter(hQuery, SYSTEM_HANDLE_COUNT_CPATH, 0, &hcSystemHandleCount);
	PdhAddCounter(hQuery, SYSTEM_THREAD_COUNT_CPATH, 0, &hcSystemThreadCount);
	PdhAddCounter(hQuery, SYSTEM_PROCESS_COUNT_CPATH, 0, &hcSystemProcessCount);

	PdhAddCounter(hQuery, CPUUSAGE_CPATH, 0, &hcCpuUsage);
	PdhAddCounter(hQuery, MEM_AVAIL_CPATH, 0, &hcMemAvail);

	PdhAddCounter(hQuery, DISK_READ_BPS_CPATH, 0, &hcDiskReadBps);
	PdhAddCounter(hQuery, DISK_WRITE_BPS_CPATH, 0, &hcDiskWriteBps);
	PdhAddCounter(hQuery, DISK_READ_IOPS_CPATH, 0, &hcDiskReadIops);
	PdhAddCounter(hQuery, DISK_WRITE_IOPS_CPATH, 0, &hcDiskWriteIops);

	PdhAddCounter(hQuery, NETWORK_BPS_RECEIVED_CPATH, 0, &hcNetworkBpsReceived);
	PdhAddCounter(hQuery, NETWORK_BPS_SENT_CPATH, 0, &hcNetworkBpsSent);

	pdhStatus = PdhCollectQueryData(hQuery);
	PdhGetFormattedCounterValue(hcSystemHandleCount, PDH_FMT_LONG, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcSystemThreadCount, PDH_FMT_LONG, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcSystemProcessCount, PDH_FMT_LONG, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcCpuUsage, PDH_FMT_DOUBLE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcMemAvail, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcDiskReadBps, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcDiskWriteBps, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcDiskReadIops, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcDiskWriteIops, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcNetworkBpsReceived, PDH_FMT_LARGE, NULL, &counterVal);
	PdhGetFormattedCounterValue(hcNetworkBpsSent, PDH_FMT_LARGE, NULL, &counterVal);

	// Write 10 records to the log file.
	for (dwCount = 0; dwCount < 100000; dwCount++)
	{
		CHAR buffer[100];
		int haveDisk = 0;
		int i = 0;
		LPWSTR pwsLogicalDiskCounterListBuffer = NULL;
		DWORD dwLogicalDiskCounterListSize = 0;
		LPWSTR pwsLogicalDiskInstanceListBuffer = NULL;
		DWORD dwLogicalDiskInstanceListSize = 0;
		LPWSTR pTemp = NULL;
		FILE *stream;
		errno_t err;

		// Wait one second between samples for a counter update.
		Sleep(SAMPLE_INTERVAL_MS);

		// Open for read (will fail if file "crt_fopen_s.c" does not exist)
		err = fopen_s(&stream, PERF_FILE, "w");
		if (err != 0)
		{
			printf("The file %s was not opened\n", PERF_FILE);
			continue;
		}

		// Determine the required buffer size for the data. 
		pdhStatus = PdhEnumObjectItems(
			NULL,                   // real-time source
			NULL,                   // local machine
			L"LogicalDisk",         // object to enumerate
			pwsLogicalDiskCounterListBuffer,   // pass NULL and 0
			&dwLogicalDiskCounterListSize,     // to get required buffer size
			pwsLogicalDiskInstanceListBuffer,
			&dwLogicalDiskInstanceListSize,
			PERF_DETAIL_WIZARD,     // counter detail level
			0);

		if (pdhStatus == PDH_MORE_DATA)
		{
			// Allocate the buffers and try the call again.
			pwsLogicalDiskCounterListBuffer = (LPWSTR)malloc(dwLogicalDiskCounterListSize * sizeof(WCHAR));
			pwsLogicalDiskInstanceListBuffer = (LPWSTR)malloc(dwLogicalDiskInstanceListSize * sizeof(WCHAR));

			_ULARGE_INTEGER lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes;

			if (NULL != pwsLogicalDiskCounterListBuffer && NULL != pwsLogicalDiskInstanceListBuffer)
			{
				pdhStatus = PdhEnumObjectItems(
					NULL,                   // real-time source
					NULL,                   // local machine
					L"LogicalDisk",         // object to enumerate
					pwsLogicalDiskCounterListBuffer,
					&dwLogicalDiskCounterListSize,
					pwsLogicalDiskInstanceListBuffer,
					&dwLogicalDiskInstanceListSize,
					PERF_DETAIL_WIZARD,     // counter detail level
					0);

				if (pdhStatus == ERROR_SUCCESS)
				{
					for (i = 0, pTemp = pwsLogicalDiskInstanceListBuffer; *pTemp != 0; pTemp += wcslen(pTemp) + 1, i++)
					{
						if (wcsstr(pTemp, L":") != NULL)
						{
							haveDisk += 1;
						}
					}
					Sleep(SAMPLE_INTERVAL_MS);
				}
				else
				{
					wprintf(L"Second PdhEnumObjectItems failed with %0x%x.\n", pdhStatus);
				}
			}
			else
			{
				wprintf(L"Unable to allocate buffers.\n");
				pdhStatus = ERROR_OUTOFMEMORY;
			}
		}
		else
		{
			wprintf(L"\nPdhEnumObjectItems failed with 0x%x.\n", pdhStatus);
		}

		pdhStatus = PdhCollectQueryData(hQuery);

		wprintf(L"\n=====================================================\n");

		sprintf_s(buffer, 100, "{");
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcSystemHandleCount, PDH_FMT_LONG, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"sys_handle\": \"%u\", ", counterVal.longValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcSystemThreadCount, PDH_FMT_LONG, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"sys_threads\": \"%u\", ", counterVal.longValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcSystemProcessCount, PDH_FMT_LONG, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"sys_processes\": \"%u\", ", counterVal.longValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcCpuUsage, PDH_FMT_DOUBLE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"cpu_usage\": \"%.2f\", ", counterVal.doubleValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		sprintf_s(buffer, 100, "\"mem_total\": \"%u\", ", totalPhysMem);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcMemAvail, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"mem_used\": \"%u\", ", totalPhysMem - counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);
		sprintf_s(buffer, 100, "\"mem_usage_rate\": \"%.2f\", ", (totalPhysMem - counterVal.largeValue) * 100.0 / totalPhysMem);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		sprintf_s(buffer, 100, "\"disk_partition_data\": {");
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		if (haveDisk)
		{
			for (i = 0, pTemp = pwsLogicalDiskInstanceListBuffer; *pTemp != 0; pTemp += wcslen(pTemp) + 1)
			{
				if (wcsstr(pTemp, L":") != NULL)
				{
					_ULARGE_INTEGER lpFreeBytesAvailableToCaller, lpTotalNumberOfBytes, lpTotalNumberOfFreeBytes;
					DWORDLONG availDiskSize, totalDiskSize;

					GetDiskFreeSpaceEx(pTemp, &lpFreeBytesAvailableToCaller, &lpTotalNumberOfBytes, &lpTotalNumberOfFreeBytes);
					availDiskSize = lpFreeBytesAvailableToCaller.QuadPart / (1024 * 1024 * 1024);
					totalDiskSize = lpTotalNumberOfBytes.QuadPart / (1024 * 1024 * 1024);

					sprintf_s(buffer, 100, "\"%s\": {\"avail_capacity\": \"%llu\", \"total_capacity\": \"%llu\"}", pTemp, availDiskSize, totalDiskSize);
					printf("%s", buffer);
					fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

					i++;
					if (i != haveDisk)
					{
						printf(", ");
						fwrite(", ", sizeof(CHAR), strlen(", "), stream);
					}
				}
			}
		}
		sprintf_s(buffer, 100, "}, ");
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);


		sprintf_s(buffer, 100, "\"disk_partition_info\": {");
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		if (haveDisk)
		{
			sprintf_s(buffer, 100, "\"sys\": [");
			printf("%s", buffer);
			fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

			for (i = 0, pTemp = pwsLogicalDiskInstanceListBuffer; *pTemp != 0; pTemp += wcslen(pTemp) + 1)
			{
				if (wcsstr(pTemp, L"C:") != NULL)
				{
					sprintf_s(buffer, 100, "\"%s\", ", pTemp);
					printf("%s", buffer);
					fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);
				}
			}
			sprintf_s(buffer, 100, "], ");
			printf("%s", buffer);
			fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

			sprintf_s(buffer, 100, "\"logic\": [");
			printf("%s", buffer);
			fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

			for (i = 0, pTemp = pwsLogicalDiskInstanceListBuffer; *pTemp != 0; pTemp += wcslen(pTemp) + 1)
			{
				if (wcsstr(pTemp, L":") != NULL)
				{
					if (wcsstr(pTemp, L"C:") != NULL)
						continue;
					sprintf_s(buffer, 100, "\"%s\", ", pTemp);
					printf("%s", buffer);
					fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);
				}
			}
			sprintf_s(buffer, 100, "], ");
			printf("%s", buffer);
			fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);
		}

		sprintf_s(buffer, 100, "}, ");
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);


		PdhGetFormattedCounterValue(hcDiskReadBps, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"disk_read_bps\": \"%u\", ", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcDiskWriteBps, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"disk_write_bps\": \"%u\", ", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcDiskReadIops, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"disk_read_iops\": \"%u\", ", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcDiskWriteIops, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"disk_write_iops\": \"%u\", ", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcNetworkBpsReceived, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"network_receive_bps\": \"%u\", ", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		PdhGetFormattedCounterValue(hcNetworkBpsSent, PDH_FMT_LARGE, NULL, &counterVal);
		sprintf_s(buffer, 100, "\"network_sent_bps\": \"%u\"}", counterVal.largeValue);
		printf("%s", buffer);
		fwrite(buffer, sizeof(CHAR), strlen(buffer), stream);

		wprintf(L"\n=====================================================\n");

		fflush(stream);
		fclose(stream);

		if (pwsLogicalDiskCounterListBuffer != NULL)
			free(pwsLogicalDiskCounterListBuffer);

		if (pwsLogicalDiskInstanceListBuffer != NULL)
			free(pwsLogicalDiskInstanceListBuffer);

		//break;
	}

cleanup:
	// Close the query object.
	if (hQuery)
		PdhCloseQuery(hQuery);
}
