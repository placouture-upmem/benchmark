// SPDX-License-Identifier: GPL-2.0
/*
 * Microbe is a microbenchmark to stress-test low-level hardware features.
 *
 *  Copyright (C) Willy Wolff <willy.mh.wolff@gmail.com>
 */

#include <limits.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "memory.h"

// pointer chasing index as global to cut optimisation
size_t idx_in_array = 0;

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

int main(int argc, char *argv[])
{
	(void) argc;
	(void) argv;

#ifdef DEBUG
	printf("argc = %d\n", argc);
	for (int idx = 0; idx < argc; ++idx) {
		printf("argv[%zu] = %s\n", idx, argv[idx]);
	}
#endif /* DEBUG */
	if (argc < 6) {
		fprintf(stderr, "USAGE: %s <array_size> <stride> <nr_iter_1> <nr_iter_2> <cpu_freq:GHz> <directory:optional>\n",
			argv[0]);
		exit(EXIT_FAILURE);
	}

	char *to_parse;
	unsigned long long int parse_me;

	size_t array_size;
	size_t stride;
	// Note: we keep nr_iter and nr_iter_2 as size_t
	//       as too limit computation whether is 32bit or 64bit
	//       nr_iter_2: outer-loop, nr_iter: inner-loop
	//       fix nr_iter first, then multiply this timing with nr_iter_2
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
		/* To facilitate analysis, we force random access, */
		/* we force the array_size to a CACHE_LINE_SIZE */
		size_t array_size_ = (array_size + ((CACHE_LINE_SIZE / sizeof(size_t))
						    - (array_size % (CACHE_LINE_SIZE / sizeof(size_t)))));
#ifdef VERBOSE_OUTPUT
		printf("array_size rounded to fit a CACHE_LINE_SIZE from %zu to %zu\n",
		       array_size, array_size_);
#endif /* VERBOSE_OUTPUT */
			array_size = array_size_;
	}

#ifdef VERBOSE_OUTPUT
	printf("sizeof(size_t) = %zu\n", sizeof(size_t));
	printf("array_size = %zu\n", array_size);
	unsigned long long array_byte_size = 1ULL * array_size * sizeof(size_t);
	printf("==> %llu b; %g Kb; %g Mb\n",
	       array_byte_size, (double) array_byte_size / 1024,
	       (double) array_byte_size / 1024 / 1024);
	/* grep MemTotal /proc/meminfo to check physical memory */

	printf("stride = %zu\n", stride);
	printf("nr_iter = %zu\n", nr_iter);
	printf("nr_iter_2 = %zu\n", nr_iter_2);
	printf("effective_nr_iter = %llu\n", effective_nr_iter);
	printf("cpu_freq = %u\n", cpu_freq);
	printf("==> %g GHz; %g MHz; %u KHz\n",
	       cpu_freq * 1e-6, cpu_freq * 1e-3, cpu_freq);
#endif /* VERBOSE_OUTPUT */

	size_t *array = NULL;

	size_t allocation_size = array_size;
	if (stride == 0) {
		/* To facilitate array indexation, */
		/* we reserve a PAGE_SIZE, even if not fully used. */
		allocation_size = (array_size + ((PAGE_SIZE / sizeof(size_t))
						 - (array_size % (PAGE_SIZE / sizeof(size_t)))));
	}

	int ret = 0;

	/* array = (size_t *) malloc(allocation_size * sizeof(size_t)); */
	/* array = (size_t *) calloc(allocation_size, sizeof(size_t)); */
	ret = posix_memalign((void **)&array, PAGE_SIZE,
			     allocation_size * sizeof(size_t));

	if ((ret != 0) | (array == NULL)) {
		char error_msg[128];
		snprintf(error_msg, sizeof error_msg,
			 "alloc array");
		handle_error_en(ret, error_msg);
	}
	
	memset(array, '\0', sizeof(*array));
	
	if (init_array(array, array_size, stride)) {
		if (stride == 0)
			print_array(array, allocation_size, nr_iter, nr_iter_2);
		else
			print_array(array, array_size, nr_iter, nr_iter_2);
	}
	
	struct timespec start;
	clock_gettime(CLOCK_TAI, &start);

	__asm__ volatile ("# START CRITICAL_SECTION");
	for (size_t iter_2 = nr_iter_2; iter_2 > 0; --iter_2) {

		__asm__ volatile ("# START INNER CRITICAL_SECTION");
/* unroll loops mitigate subs and branch for the iterator */
#if defined(__unroll_cl__)
/* beware L1-icache size */
#if defined(__clang__)
#pragma clang loop unroll_count(UNROLL)
#elif defined(__GNUC__) && !defined(__llvm__) && !defined(__INTEL_COMPILER)
int const unroll_fact = UNROLL;
#pragma GCC unroll unroll_fact
#endif /* defined(__clang__) */
#endif /* defined(__unroll_cl__) */
		for (unsigned long long iter = nr_iter; iter > 0; --iter) {
			idx_in_array = array[idx_in_array];
		}
		__asm__ volatile ("# END INNER CRITICAL_SECTION");
	}
	__asm__ volatile ("# END CRITICAL_SECTION");

	struct timespec stop;
	clock_gettime(CLOCK_TAI, &stop);

	free(array);

	unsigned long long start_ = start.tv_sec * 1000000000ULL + start.tv_nsec;
	unsigned long long stop_ = stop.tv_sec * 1000000000ULL + stop.tv_nsec;
	
	unsigned long long delta = stop_ - start_;
	double time_per_iter = (double)delta / effective_nr_iter;
	double cycles_per_iter = time_per_iter * cpu_freq * 1e-6;

#ifdef VERBOSE_OUTPUT
	printf("total time = %llu ns; %g s\n", delta, (double) delta * 1e-9);
	printf("time per iter %g ns\n", time_per_iter);
	printf("estimated cycles per iter %g c\n", cycles_per_iter);
#else
	printf("%zu,%zu,%llu,%u,"
	       "%llu,%g,%g"
	       "\n",
	       array_size, stride, effective_nr_iter, cpu_freq,
	       delta, time_per_iter, cycles_per_iter);	
#endif /* VERBOSE_OUTPUT */

	if (argc == 7) {
		char general_path[4096] = {0};
		strncpy(general_path, argv[6], sizeof general_path - 1);

		char fd_summary_path[sizeof general_path + 13] = {0};
		snprintf(fd_summary_path, sizeof fd_summary_path, "%s/summary.csv",
			 general_path);

		FILE *fd_summary;
		fd_summary = fopen(fd_summary_path, "w");
		if (!fd_summary) {
			char error_msg[sizeof fd_summary_path + 8];
			snprintf(error_msg, sizeof error_msg,
			 "open(%s)", fd_summary_path);
			handle_perror(error_msg);
		}

		fprintf(fd_summary, "%zu,%zu,%llu,%u,"
			"%llu,%llu,"
			"%llu,%g,%g"
			"\n",
			array_size, stride, effective_nr_iter, cpu_freq,
			start_, stop_,
			delta, time_per_iter, cycles_per_iter);
		fclose(fd_summary);
	}
	
	return EXIT_SUCCESS;
}
