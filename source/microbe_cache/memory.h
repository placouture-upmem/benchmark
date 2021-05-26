// SPDX-License-Identifier: GPL-2.0
/*
 * Microbe is a microbenchmark to stress-test low-level hardware features.
 *
 * memory.h - Initialise array indices to show different memory access pattern.
 * Ideas and concepts in this file are largely inspired from other project on the subject.
 *
 *  Copyright (C) Willy Wolff <willy.mh.wolff@gmail.com>
 */

#include <stdbool.h>

void print_array(size_t *arr_ptr, size_t nr_elements,
		 size_t nr_iter, size_t nr_iter_2)
{
	bool print_sequence = false;
	size_t virtual_cache_line = 0;

	printf("print array:\n");
	for (size_t i = 0; i < nr_elements; ++i) {
		if ((i % (CACHE_LINE_SIZE / sizeof(size_t)) == 0)) {
			printf("\n%04zu => %04zu: ", virtual_cache_line, i);
			virtual_cache_line++;
		}
		printf("%04zu, ", arr_ptr[i]);
	}
	printf("\n");

	if (print_sequence) {
		printf("print sequence of size %zu * %zu:\n", nr_iter, nr_iter_2);
		size_t in_array = 0;
		for (size_t j = 0; j < nr_iter_2; j++) {
			for (size_t i = 0; i < nr_iter; i++) {
				printf("%zu, ", in_array);
				in_array = arr_ptr[in_array];
			}
		}
		printf("\n");
	}
}

int verify_array(size_t *arr_ptr, size_t nr_elements)
{
	size_t idx = 0;
	size_t counter = 0;

	bool finished = false;

	size_t* verif = (size_t *) calloc(nr_elements, sizeof(size_t));

	while (!finished) {
		verif[idx] = verif[idx] + 1;
		counter++;
		idx = arr_ptr[idx];

		if (counter >= nr_elements || idx == 0)
			finished = true;
	}

	bool error = false;

	size_t stride = CACHE_LINE_SIZE / sizeof(size_t);

	for (size_t i = 0; i < nr_elements; i += stride) {
		if (verif[i] != 1) {
			fprintf(stderr, "Error at Element [%zu], accessed %zu times\n",
				i, verif[i]);
			error = true;
		}
	}
	free(verif);

	return error ? -1 : 0;
}

void show_bits(size_t val)
{
	for (int n = 8 * sizeof(val) - 1; n >= 0; n--) {
		printf("%zu", (val >> n) & 1);
		if (!(n % 4))
			printf(",");
	}
	printf("\n");
}

unsigned get_bitmask(size_t bits)
{
	unsigned mask = 0;
	for (size_t idx = 0; idx < bits; idx++)
		mask += 0x1 << idx;

	return mask;
}

size_t init_page(size_t *arr_n_ptr, size_t page_offset, size_t nr_cache_lines)
{
#ifdef DEBUG
	printf("\n== init_page: offset = %zu, nr_cache_lines = %zu\n\n",
	       page_offset, nr_cache_lines);
#endif /* DEBUG */

	size_t lfsr = 0x1;
	unsigned mask = get_bitmask(6);

	size_t bucket[nr_cache_lines];
	bucket[0] = lfsr;
	for (size_t idx = 1; idx < nr_cache_lines; ++idx) {
		size_t bit = 0;
		bit = ((lfsr >> 1) & mask) ^ ((lfsr >> 2) & mask) ^ ((lfsr >> 4) & mask) ^ ((lfsr >> 5) & mask);

		lfsr = ((lfsr << 1) & mask) | (bit & 0x1);

		bucket[idx] = lfsr;
	}

#ifdef DEBUG
#ifdef DEBUG_LFSR
	for (size_t idx = 0; idx < nr_cache_lines; ++idx) {
		printf("bucket[%zu] = %zu =>\t\t\t", idx, bucket[idx]);
		show_bits(bucket[idx]);
	}

	size_t period = 0;
	for (size_t idx = 0; idx < nr_cache_lines; ++idx) {
		for (size_t idx_ = 0; idx_ < nr_cache_lines; ++idx_) {
			if (idx == idx_)
				continue;

			if (bucket[idx] == bucket[idx_]) {
				period = idx_ - idx;
				goto out;
			}
		}
	}

out:
	printf("period = %zu\n", period);
#endif /* DEBUG_LFSR */
#endif /* DEBUG */

	size_t last_idx = page_offset;
	for (size_t idx = 0; idx < nr_cache_lines - 1; ++idx) {
		size_t random_cache_line = bucket[idx];
		size_t next_idx = page_offset + (random_cache_line * CACHE_LINE_SIZE) / sizeof(size_t);
		arr_n_ptr[last_idx] = next_idx;

#ifdef DEBUG
		printf("idx = %zu, cache_line = %zu, next_idx = %zu, last_idx = %zu\n",
		       idx, random_cache_line, next_idx, last_idx);
#endif /* DEBUG */

		last_idx = next_idx;
	}

	return last_idx;
}

void init_array(size_t* arr_n_ptr, size_t nr_elements, size_t stride)
{
	if (stride != 0) {
		for (size_t i = 0; i < nr_elements; i++) {
			arr_n_ptr[i % nr_elements] = (i + stride) % nr_elements;
		}
	} else {
#ifdef DEBUG
		printf("\n\n== ramdomise array\n");
#endif /* DEBUG */

		size_t nr_pages = (nr_elements * sizeof(size_t)) / PAGE_SIZE;

		size_t nr_cache_lines_per_page = PAGE_SIZE / CACHE_LINE_SIZE;
		size_t nr_elements_per_page = PAGE_SIZE / sizeof(size_t);
		size_t nr_remain_elements = (nr_elements - (nr_pages * nr_elements_per_page));

#ifdef DEBUG
		size_t nr_cache_lines = (nr_elements * sizeof(size_t)) / CACHE_LINE_SIZE;

		printf("PAGE_SIZE = %zu\n", PAGE_SIZE);
		printf("CACHE_LINE_SIZE = %zu\n", CACHE_LINE_SIZE);
		printf("nr_cache_lines_per_page = %zu\n", nr_cache_lines_per_page);

		printf("nr_pages = %zu\n", nr_pages);
		printf("nr_cache_lines = %zu\n", nr_cache_lines);

		printf("nr_elements_per_page = %zu\n", nr_elements_per_page);
		printf("nr_remain_elements = %zu\n", nr_remain_elements);
#endif /* DEBUG */

		size_t last_idx = 0;

		for (size_t idx_page = 0; idx_page < nr_pages; ++idx_page) {
			size_t page_offset = idx_page * nr_elements_per_page;
#ifdef DEBUG
			printf("\n== new page: idx_page = %zu, page offset = %zu, last_idx = %zu\n",
			       idx_page, page_offset, last_idx);
#endif /* DEBUG */

			arr_n_ptr[last_idx] = page_offset;
			last_idx = init_page(arr_n_ptr, page_offset, nr_cache_lines_per_page);

#ifdef DEBUG
			printf("last_idx = %zu\n", last_idx);
#endif /* DEBUG */

		}

		if (nr_remain_elements) {
			size_t page_offset = nr_pages * nr_elements_per_page;
#ifdef DEBUG
			printf("\n== last partial page:\n");
			printf("page_offset = %zu\n", page_offset);
#endif /* DEBUG */

			arr_n_ptr[last_idx] = page_offset;
			last_idx = init_page(arr_n_ptr, page_offset,
					     (nr_remain_elements * sizeof(size_t)) / CACHE_LINE_SIZE);
		}

		arr_n_ptr[last_idx] = 0;
	}
}
