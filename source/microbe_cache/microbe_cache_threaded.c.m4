// SPDX-License-Identifier: GPL-2.0
/*
 * Microbe is a microbenchmark to stress-test low-level hardware features.
 *
 *  Copyright (C) Willy Wolff <willy.mh.wolff@gmail.com>
 */

#define _GNU_SOURCE
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/types.h>

#include <limits.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>

#include "memory.h"

include(`forloop.m4')

#if defined(GLOBAL_ITERATOR)
/* if the iterator is a global, you have a store */
forloop(`f', `1', THREAD_COUNT, `forloop(`i', `1', ACCESS_REQ, `format(`size_t idx_in_array_%d_%d = 0;
', f, i)')')
#endif /* GLOBAL_ITERATOR */

#define handle_perror(msg)				\
	do {						\
		fprintf(stderr,				\
			"%s:%d:%s(): PERROR: ",		\
			__FILE__, __LINE__, __func__);	\
		perror(msg);				\
		exit(EXIT_FAILURE);			\
	} while (0)

#define handle_error_en(en, msg)			\
	do {						\
		fprintf(stderr,				\
			"%s:%d:%s(): PERROR: ",		\
			__FILE__, __LINE__, __func__);	\
		errno = en;				\
		perror(msg);				\
		exit(EXIT_FAILURE);			\
	} while (0)

pid_t gettid()
{
	pid_t tid = syscall(SYS_gettid);

	if (tid < 0)
		handle_perror("gettid");

	return tid;
}

struct thread_info {
	pthread_barrier_t *barrier;
	forloop(`i', `1', ACCESS_REQ, `format(`size_t *arr_n_ptr_%d;
	', i)')
	forloop(`i', `1', ACCESS_REQ, `format(`size_t *idx_in_array_%d;
	', i)')

	size_t thread_id;
	size_t nr_iter_2;
	size_t nr_iter;
};

void* thread_func(void* arg)
{
	printf("Inside the thread\n");
	struct thread_info *tinfo = arg;
	pthread_barrier_t *barrier = tinfo->barrier;
	forloop(`i', `1', ACCESS_REQ, `format(`size_t *arr_n_ptr_%d = tinfo->arr_n_ptr_%d;
	', i, i)')
	#if defined(GLOBAL_ITERATOR)
	forloop(`i', `1', ACCESS_REQ, `format(`size_t *idx_in_array_%d = tinfo->idx_in_array_%d;
	', i, i)')
	#endif /* GLOBAL_ITERATOR */

	size_t thread_id = tinfo->thread_id;
	size_t nr_iter_2 = tinfo->nr_iter_2;
	size_t nr_iter = tinfo->nr_iter;

#if defined(LOCAL_ITERATOR)
	/* if the iterator is a local variable, we could have pure load */
	/* however, this depends on the number of hardware register available */
	/* and on the loop unroll factor */
	forloop(`i', `1', ACCESS_REQ, `format(`size_t idx_in_array_%d = 0;
	', i)')
#endif /* LOCAL_ITERATOR */

	/* sync for all thread creation */
	pthread_barrier_wait(barrier);

	/* sync for main benchmark clock */
	pthread_barrier_wait(barrier);

	struct timespec export_time_start;
	clock_gettime(CLOCK_REALTIME, &export_time_start);

	struct timespec start;
	clock_gettime(CLOCK_MONOTONIC_RAW, &start);

	__asm__ volatile ("# critical in"); /* clang mess up location */
	for (size_t iter_2 = nr_iter_2; iter_2 > 0; --iter_2) {
#if defined(__unroll_critical__)
/* beware L1-icache size */
#if defined(__clang__)
#pragma clang loop unroll_count(UNROLL)
#elif defined(__GNUC__) && !defined(__clang__) && !defined(__INTEL_COMPILER)
		int const unroll_fact = UNROLL;
#pragma GCC unroll unroll_fact
#endif /* defined(__clang__) */
#endif /* defined(__unroll_cl__) */
		for (size_t iter = nr_iter; iter > 0; --iter) {
		#if defined(GLOBAL_ITERATOR)
			forloop(`i', `1', ACCESS_REQ, `format(`*idx_in_array_%d = arr_n_ptr_%d[*idx_in_array_%d];
			', i, i, i)')
		#endif /* GLOBAL_ITERATOR */

		#if defined(LOCAL_ITERATOR)
			forloop(`i', `1', ACCESS_REQ, `format(`idx_in_array_%d = arr_n_ptr_%d[idx_in_array_%d];
			', i, i, i)')
		#endif /* LOCAL_ITERATOR */
		}
	}
	__asm__ volatile ("# critical out"); /* clang mess up location */

	struct timespec stop;
	clock_gettime(CLOCK_MONOTONIC_RAW, &stop);

	struct timespec export_time_stop;
	clock_gettime(CLOCK_REALTIME, &export_time_stop);

	/* sync for main benchmark clock */
	pthread_barrier_wait(barrier);

	pid_t tid = gettid();

	char file_name[42];
	snprintf(file_name, sizeof file_name,
		 "timing_%zu_%d.csv", thread_id, tid);

	FILE *fd_timing = fopen(file_name, "w");
	if (!fd_timing) {
		perror(file_name);
		exit(EXIT_FAILURE);
	}
	fprintf(fd_timing, "%10lu%09lu,start\n", export_time_start.tv_sec, export_time_start.tv_nsec);
	fprintf(fd_timing, "%10lu%09lu,stop\n", export_time_stop.tv_sec, export_time_stop.tv_nsec);
	fclose(fd_timing);

	#if defined(LOCAL_ITERATOR)
	forloop(`i', `1', ACCESS_REQ, `format(`printf("print to cut optimisation %s\n", idx_in_array_%d);
	', %zu, i)')
	#endif /* LOCAL_ITERATOR */

	return NULL;
}

int main(int argc, char *argv[]) {
	(void) argc;
	(void) argv;

#ifdef DEBUG
	printf("argc = %d\n", argc);
	for (int idx = 0; idx < argc; ++idx) {
		printf("argv[%zu] = %s\n", idx, argv[idx]);
	}
#endif /* DEBUG */
	if (argc != 8) {
		fprintf(stderr, "USAGE: %s <array_size> <stride> <nr_iter_1> <nr_iter_2> <cpu_freq:KHz> <directory_to_put_results> <id_run>\n",
			argv[0]);
		exit(EXIT_FAILURE);
	}

	char *to_parse;
	unsigned long long int parse_me;

	size_t array_size;
	size_t stride;
	// Note: we keep nr_iter and nr_iter_2 as size_t
	//       as too limit computation whether it is 32bit or 64bit
	//       nr_iter_2: outer-loop, nr_iter: inner-loop
	//       fix nr_iter first, then multiply this timing with nr_iter_2
	//       a nice idea is to set nr_iter to compute for 1s, and nr_iter_2 is a second multiplyer
	size_t nr_iter;
	size_t nr_iter_2;

	errno = 0;
	to_parse = argv[1];
	parse_me = strtoull(to_parse, NULL, 10);
	if ((parse_me == ULLONG_MAX && errno == ERANGE)
	    || (parse_me > SIZE_MAX)) {
		fprintf(stderr, "<array_size> overflow %s > (%llu | %zu)\n",
			to_parse, ULLONG_MAX, SIZE_MAX);
		exit(ERANGE);
	}
	array_size = (size_t) parse_me;

	errno = 0;
	to_parse = argv[2];
	parse_me = strtoull(to_parse, NULL, 10);
	if ((parse_me == ULLONG_MAX && errno == ERANGE)
	    || (parse_me > SIZE_MAX)) {
		fprintf(stderr, "<stride> overflow %s > (%llu | %zu)\n",
			to_parse, ULLONG_MAX, SIZE_MAX);
		exit(ERANGE);
	}
	stride = (size_t) parse_me;

	errno = 0;
	to_parse = argv[3];
	parse_me = strtoull(to_parse, NULL, 10);
	if ((parse_me == ULLONG_MAX && errno == ERANGE)
	    || (parse_me > SIZE_MAX - 1)) {
		fprintf(stderr, "<nr_iter> overflow %s > (%llu | %zu)\n",
			to_parse, ULLONG_MAX, SIZE_MAX - 1);
		exit(ERANGE);
	}
	nr_iter = (size_t) parse_me;

	errno = 0;
	to_parse = argv[4];
	parse_me = strtoull(to_parse, NULL, 10);
	if ((parse_me == ULLONG_MAX && errno == ERANGE)
	    || (parse_me > SIZE_MAX - 1)) {
		fprintf(stderr, "<nr_iter_2> overflow %s > (%llu | %zu)\n",
			to_parse, ULLONG_MAX, SIZE_MAX - 1);
		exit(ERANGE);
	}
	nr_iter_2 = (size_t) parse_me;

	unsigned long long effective_nr_iter;
	if (__builtin_mul_overflow(1ULL * nr_iter, 1ULL * nr_iter_2, &effective_nr_iter)) {
		fprintf(stderr, "effective_nr_iter overflowed\n");
		exit(ERANGE);
	}

	unsigned int cpu_freq = atoi(argv[5]);

	if (stride == 0) {
		size_t array_size_ = (array_size + ((CACHE_LINE_SIZE / sizeof(size_t))
						    - (array_size % (CACHE_LINE_SIZE / sizeof(size_t)))));
		printf("array_size rounded to fit a CACHE_LINE_SIZE from %zu to %zu\n",
		       array_size, array_size_);
			array_size = array_size_;
	}

	printf("sizeof(size_t) = %zu\n", sizeof(size_t));
	printf("array_size = %zu\n", array_size);
	unsigned long long array_byte_size = 1ULL * array_size * sizeof(size_t);
	printf("==> %llu b; %g Kb; %g Mb\n",
	       array_byte_size, (double) array_byte_size / 1024,
	       (double) array_byte_size / 1024 / 1024);
	// grep MemTotal /proc/meminfo to check physical memory

	printf("stride = %zu\n", stride);
	printf("nr_iter = %zu\n", nr_iter);
	printf("nr_iter_2 = %zu\n", nr_iter_2);
	printf("effective_nr_iter = %llu\n", effective_nr_iter);
	printf("cpu_freq = %u\n", cpu_freq);
	printf("==> %g GHz; %g MHz; %u KHz\n",
	       cpu_freq * 1e-6, cpu_freq * 1e-3, cpu_freq);

	size_t allocation_size = array_size;
	if (stride == 0) {
		// To facilitate array indexation
		allocation_size = (array_size + ((PAGE_SIZE / sizeof(size_t))
						 - (array_size % (PAGE_SIZE / sizeof(size_t)))));
	}

	int ret;

	forloop(`f', `1', THREAD_COUNT, `forloop(`i', `1', ACCESS_REQ, `format(`
	size_t *arr_n_ptr_%d_%d = NULL;
	ret = posix_memalign((void **)&arr_n_ptr_%d_%d, PAGE_SIZE,
			     allocation_size * sizeof(size_t));
	if ((ret != 0) | (arr_n_ptr_%d_%d == NULL)) {
		char error_msg[128];
		snprintf(error_msg, sizeof error_msg,
			 "alloc arr_n_ptr_%d_%d");
		handle_error_en(ret, error_msg);
	}
	memset(arr_n_ptr_%d_%d, 0, sizeof(*arr_n_ptr_%d_%d));
	if (init_array(arr_n_ptr_%d_%d, array_size, stride)) {
		if (stride == 0)
			print_array(arr_n_ptr_%d_%d, allocation_size, nr_iter, nr_iter_2);
		else
			print_array(arr_n_ptr_%d_%d, array_size, nr_iter, nr_iter_2);
	}
	', f, i, f, i, f, i, f, i, f, i, f, i, f, i, f, i, f, i)')')

	pthread_barrier_t barrier;
	pthread_barrier_init(&barrier, NULL, THREAD_COUNT + 1);

	forloop(`f', `1', THREAD_COUNT, `format(`
	pthread_t thread_%d;
	struct thread_info tinfo_%d;
	tinfo_%d.barrier = &barrier;
	tinfo_%d.thread_id = %d;
	tinfo_%d.nr_iter_2 = nr_iter_2;
	tinfo_%d.nr_iter = nr_iter;
	', f, f, f, f, f, f, f)')

	forloop(`f', `1', THREAD_COUNT, `forloop(`i', `1', ACCESS_REQ, `format(`tinfo_%d.arr_n_ptr_%d = arr_n_ptr_%d_%d;
	', f, i, f, i)')')

#if defined(GLOBAL_ITERATOR)
	forloop(`f', `1', THREAD_COUNT, `forloop(`i', `1', ACCESS_REQ, `format(`tinfo_%d.idx_in_array_%d = &idx_in_array_%d_%d;
	', f, i, f, i)')')
#endif /* GLOBAL_ITERATOR */

	forloop(`f', `1', THREAD_COUNT, `format(`
	if ((ret = pthread_create(&thread_%d, NULL, thread_func, &tinfo_%d)) != 0)
		handle_error_en(ret, "pthread_create thread_%d");
	', f, f, f)')

	pthread_barrier_wait(&barrier);

	struct timespec export_time_start;
	clock_gettime(CLOCK_REALTIME, &export_time_start);

	struct timespec start;
	clock_gettime(CLOCK_MONOTONIC_RAW, &start);

	pthread_barrier_wait(&barrier);

/* threads are working */

	pthread_barrier_wait(&barrier);

	struct timespec stop;
	clock_gettime(CLOCK_MONOTONIC_RAW, &stop);

	struct timespec export_time_stop;
	clock_gettime(CLOCK_REALTIME, &export_time_stop);

	FILE *fd_timing = fopen("timing.csv", "w");
	if (!fd_timing) {
		perror("timing.csv");
		exit(EXIT_FAILURE);
	}
	fprintf(fd_timing, "%10lu%09lu,start\n", export_time_start.tv_sec, export_time_start.tv_nsec);
	fprintf(fd_timing, "%10lu%09lu,stop\n", export_time_stop.tv_sec, export_time_stop.tv_nsec);
	fclose(fd_timing);

	forloop(`f', `1', THREAD_COUNT, `format(`
	if ((ret = pthread_join(thread_%d, NULL)) != 0)
		handle_error_en(ret, "pthread_join thread_%d");
	', f, f)')

	forloop(`f', `1', THREAD_COUNT, `forloop(`i', `1', ACCESS_REQ, `format(`free(arr_n_ptr_%d_%d);
	', f, i)')')

	unsigned long long start_ = start.tv_sec * 1000000000ULL + start.tv_nsec;
	unsigned long long stop_ = stop.tv_sec * 1000000000ULL + stop.tv_nsec;

	unsigned long long delta = stop_ - start_;
	double time_per_iter = (double)delta / effective_nr_iter;
	double cycles_per_iter = time_per_iter * cpu_freq * 1e-6;

	printf("total time = %llu ns; %g s\n", delta, (double) delta * 1e-9);
	printf("time per iter %g ns\n", time_per_iter);
	printf("estimated cycles per iter %g c\n", cycles_per_iter);

	printf("\nTiming depends on the memory allocator, CPUs and memory frequency, "
	       "system busyness, number of iterations, etc...\n"
	       "Set the number of iteration to run for at least a few seconds.\n"
	       "Run multiple times before making any conclusion.\n\n");

	char general_path[4096] = {0};
	strncpy(general_path, argv[6], sizeof general_path - 1);

	char fd_summary_path[sizeof general_path + 13] = {0};
	snprintf(fd_summary_path, sizeof fd_summary_path, "%s/summary.csv",
		 general_path);

	FILE *fd_summary;
	fd_summary = fopen(fd_summary_path, "a");
	if (!fd_summary) {
		char error_msg[sizeof fd_summary_path + 8];
		snprintf(error_msg, sizeof error_msg,
		 "open(%s)", fd_summary_path);
		handle_perror(error_msg);
	}

	fprintf(fd_summary, "%s,%s,%010zu,%zu,%llu,%u,%llu,%g,%g\n",
		argv[7], argv[0], array_size, stride, effective_nr_iter, cpu_freq,
		delta, time_per_iter, cycles_per_iter);
	fclose(fd_summary);

	return EXIT_SUCCESS;
}
