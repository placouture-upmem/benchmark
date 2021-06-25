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

define(mym4for,
       `ifelse(eval(($4==0) || (($4>0) && ($2>$3)) || (($4<0) && ($2<$3))),1,,
       `define(`$1',$2)$5`'mym4for(`$1',eval($2 + $4),$3,$4,`$5')')')

#if defined(GLOBAL_ITERATOR)
/* if the iterator is a global, you have a store */
mym4for(`th_idx', `1', THREAD_COUNT, +1, `mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t idx_in_array_%d_%d = 0;
', th_idx, i)')')
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
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t *arr_n_ptr_%d;
	', i)')
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t *idx_in_array_%d;
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
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t *arr_n_ptr_%d = tinfo->arr_n_ptr_%d;
	', i, i)')
#if defined(GLOBAL_ITERATOR)
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t *idx_in_array_%d = tinfo->idx_in_array_%d;
	', i, i)')
#endif /* GLOBAL_ITERATOR */

	size_t thread_id = tinfo->thread_id;
	size_t nr_iter_2 = tinfo->nr_iter_2;
	size_t nr_iter = tinfo->nr_iter;

#if defined(LOCAL_ITERATOR)
	/* if the iterator is a local variable, we could have pure load */
	/* however, this depends on the number of hardware register available */
	/* and on the loop unroll factor */
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`size_t idx_in_array_%d = 0;
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

	__asm__ volatile ("# critical in");
	for (size_t iter_2 = nr_iter_2; iter_2 > 0; --iter_2) {
		size_t iter = nr_iter;

		if (iter % UNROLL == 0) {
		  goto unroll_none;
		}mym4for(`unroll_idx', `1', UNROLL - 1, +1, `format(` else if (iter %% UNROLL == (UNROLL - %d)) {
		  iter = iter - (UNROLL - %d);
		  goto unroll_%d;
		}', unroll_idx, unroll_idx, unroll_idx)')

		mym4for(`unroll_idx', `1', UNROLL - 1, +1, `format(`
	unroll_%d:', unroll_idx)
		#if defined(GLOBAL_ITERATOR)
			mym4for(`i', `1', ACCESS_REQ, +1, `format(`*idx_in_array_%d = arr_n_ptr_%d[*idx_in_array_%d];
			', i, i, i)')
		#endif /* GLOBAL_ITERATOR */

		#if defined(LOCAL_ITERATOR)
			mym4for(`i', `1', ACCESS_REQ, +1, `format(`idx_in_array_%d = arr_n_ptr_%d[idx_in_array_%d];
			', i, i, i)')
		#endif /* LOCAL_ITERATOR */
		')

	unroll_none:
		for (; iter > 0; iter -= UNROLL) {
			mym4for(`unroll_idx', `0', UNROLL - 1, +1, `
		#if defined(GLOBAL_ITERATOR)
			mym4for(`i', `1', ACCESS_REQ, +1, `format(`*idx_in_array_%d = arr_n_ptr_%d[*idx_in_array_%d];
			', i, i, i)')
		#endif /* GLOBAL_ITERATOR */

		#if defined(LOCAL_ITERATOR)
			mym4for(`i', `1', ACCESS_REQ, +1, `format(`idx_in_array_%d = arr_n_ptr_%d[idx_in_array_%d];
			', i, i, i)')
		#endif /* LOCAL_ITERATOR */
		')
		}
	}
	__asm__ volatile ("# critical out");

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
	mym4for(`i', `1', ACCESS_REQ, +1, `format(`printf("print to cut optimisation %s\n", idx_in_array_%d);
	', %zu, i)')
#endif /* LOCAL_ITERATOR */

	return NULL;
}

int main(int argc, char *argv[]) {
	if (argc != 7) {
		fprintf(stderr, "USAGE: %s <sequence_file> <nr_iter_1> <nr_iter_2> <cpu_freq:KHz> <directory_to_put_results> <id_run>\n",
			argv[0]);
		exit(EXIT_FAILURE);
	}

	char *to_parse;
	unsigned long long int parse_me;

	size_t array_size;
	size_t stride;
	size_t page_stride;
	// Note: we keep nr_iter and nr_iter_2 as size_t
	//       as too limit computation whether it is 32bit or 64bit
	//       nr_iter_2: outer-loop, nr_iter: inner-loop
	//       fix nr_iter first, then multiply this timing with nr_iter_2
	//       a nice idea is to set nr_iter to compute for 1s, and nr_iter_2 is a second multiplyer
	size_t nr_iter;
	size_t nr_iter_2;

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

	int ret = 0;

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `mym4for(`i', `1', ACCESS_REQ, +1, `format(`
	size_t *arr_n_ptr_%d_%d = NULL;

	FILE *sequence_%d_%d = fopen(argv[1], "rb");
	if (!sequence_%d_%d) {
		char error_msg[128];
		snprintf(error_msg, sizeof error_msg, "%s", argv[1]);
		handle_perror(error_msg);
	}

	if (fread(&array_size, sizeof(size_t), 1, sequence_%d_%d) < 1)
		handle_perror("fread array_size");
	if (fread(&stride, sizeof(size_t), 1, sequence_%d_%d) < 1)
		handle_perror("fread stride");
	if (fread(&page_stride, sizeof(size_t), 1, sequence_%d_%d) < 1) 
		handle_perror("fread page_stride");

	printf("preparing arr_n_ptr_%d_%d of size %s, stride %s, page_stride %s\n", array_size, stride, page_stride);

	printf("allocation\n");

	/* arr_n_ptr_%d_%d = (size_t *) malloc(array_size * sizeof(size_t)); */

	ret = posix_memalign((void **)&arr_n_ptr_%d_%d, PAGE_SIZE,
			     array_size * sizeof(size_t));

	if ((ret != 0) | (arr_n_ptr_%d_%d == NULL)) {
		char error_msg[128];
		snprintf(error_msg, sizeof error_msg,
			 "alloc arr_n_ptr_%d_%d");
		handle_error_en(ret, error_msg);
	}

	memset(arr_n_ptr_%d_%d, SIZE_MAX, array_size * sizeof(size_t));

	if (stride == 0) {
		printf("reading\n");
		if (fread(arr_n_ptr_%d_%d, sizeof(size_t), array_size, sequence_%d_%d) < array_size)
			handle_perror("fread array");
	} else {
		printf("Init array\n");
		for (size_t idx = 0; idx < array_size; idx++) {
			arr_n_ptr_%d_%d[idx %s array_size] = (idx + stride) %s array_size;
		}
	}

	printf("done\n");

	fclose(sequence_%d_%d);
	printf("preparation done\n");

	', th_idx, i,
	   th_idx, i,
	   th_idx, i,
	   %s,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i, %zu, %zu, %zu,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i,
	   th_idx, i, th_idx, i,
	   th_idx, i, %, %,
	   th_idx, i)')')

	printf("sizeof(size_t) = %zu\n", sizeof(size_t));
	printf("array_size = %zu\n", array_size);
	size_t array_byte_size = array_size * sizeof(size_t);

	printf("==> %zu B; %f KB; %f MB; %f GB\n",
	       array_byte_size, (double) array_byte_size / 1024.,
	       (double) array_byte_size / 1024. / 1024.,
	       (double) array_byte_size / 1024. / 1024. / 1024.);
	// grep MemTotal /proc/meminfo to check physical memory
	printf("stride = %zu\n", stride);
	printf("page_stride = %zu\n", page_stride);
	printf("nr_iter = %zu\n", nr_iter);
	printf("nr_iter_2 = %zu\n", nr_iter_2);
	printf("effective_nr_iter = %llu\n", effective_nr_iter);
	printf("cpu_freq = %u\n", cpu_freq);
	printf("==> %g GHz; %g MHz; %u KHz\n",
	       cpu_freq * 1e-6, cpu_freq * 1e-3, cpu_freq);

	pthread_barrier_t barrier;
	pthread_barrier_init(&barrier, NULL, THREAD_COUNT + 1);

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `format(`
	pthread_t thread_%d;
	struct thread_info tinfo_%d;
	tinfo_%d.barrier = &barrier;
	tinfo_%d.thread_id = %d;
	tinfo_%d.nr_iter_2 = nr_iter_2;
	tinfo_%d.nr_iter = nr_iter;
	', th_idx, th_idx, th_idx, th_idx, th_idx, th_idx, th_idx)')

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `mym4for(`i', `1', ACCESS_REQ, +1, `format(`tinfo_%d.arr_n_ptr_%d = arr_n_ptr_%d_%d;
	', th_idx, i, th_idx, i)')')

#if defined(GLOBAL_ITERATOR)
	mym4for(`th_idx', `1', THREAD_COUNT, +1, `mym4for(`i', `1', ACCESS_REQ, +1, `format(`tinfo_%d.idx_in_array_%d = &idx_in_array_%d_%d;
	', th_idx, i, th_idx, i)')')
#endif /* GLOBAL_ITERATOR */

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `format(`
	if ((ret = pthread_create(&thread_%d, NULL, thread_func, &tinfo_%d)) != 0)
		handle_error_en(ret, "pthread_create thread_%d");
	', th_idx, th_idx, th_idx)')

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

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `format(`
	if ((ret = pthread_join(thread_%d, NULL)) != 0)
		handle_error_en(ret, "pthread_join thread_%d");
	', th_idx, th_idx)')

	mym4for(`th_idx', `1', THREAD_COUNT, +1, `mym4for(`i', `1', ACCESS_REQ, +1, `format(`free(arr_n_ptr_%d_%d);
	', th_idx, i)')')

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
	strncpy(general_path, argv[5], sizeof general_path - 1);

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

	fprintf(fd_summary, "%s,%s,%zu,%zu,%llu,%u,%llu,%g,%g\n",
		argv[6], argv[0], array_size, stride, effective_nr_iter, cpu_freq,
		delta, time_per_iter, cycles_per_iter);
	fclose(fd_summary);

	return EXIT_SUCCESS;
}
