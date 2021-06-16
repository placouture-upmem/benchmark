#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define ELTS_SIZE (sizeof(size_t))

#define CACHE_LINE_SIZE 64
#define PAGE_SIZE 4096
#define CACHE_LINE_PER_PAGE (PAGE_SIZE / CACHE_LINE_SIZE)

#define PTRS_PER_PTE 512
#define PTRS_PER_PMD 1
#define PTRS_PER_PUD 1
#define PTRS_PER_P4D 1
#define PTRS_PER_PGD 64

#define NR_LAST_PAGE_ENTRY_TO_AVOID (PTRS_PER_PTE / 2)


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



struct location {
	size_t cl;
	size_t pte;
	size_t pmd;
	size_t pud;
	size_t p4d;
	size_t pgd;
};

size_t location_to_byte(struct location *l)
{
	return ((l->cl * CACHE_LINE_SIZE)
		+ (l->pte * PAGE_SIZE)
		+ (l->pmd * PTRS_PER_PTE * PAGE_SIZE)
		+ (l->pud * PTRS_PER_PMD * PTRS_PER_PTE * PAGE_SIZE)
		+ (l->p4d * PTRS_PER_PUD * PTRS_PER_PMD * PTRS_PER_PTE * PAGE_SIZE)
		+ (l->pgd * PTRS_PER_P4D * PTRS_PER_PUD * PTRS_PER_PMD * PTRS_PER_PTE * PAGE_SIZE));
}

void location_print(struct location *l)
{
	printf("%zu %zu %zu %zu %zu %zu",
	       l->pgd, l->p4d, l->pud, l->pmd, l->pte, l->cl);
}

void location_swap(struct location *left, struct location *right)
{
	struct location tmp;
	memcpy(&tmp, right, sizeof(struct location));
	memcpy(right, left, sizeof(struct location));
	memcpy(left, &tmp, sizeof(struct location));
}

bool location_has_subset(struct location *entry, struct location *comp)
{
	return ((entry->cl == comp->cl)
		|| (entry->pte == comp->pte)
		|| (PTRS_PER_PMD > 1 ? entry->pmd == comp->pmd : false)
		|| (PTRS_PER_PUD > 1 ? entry->pud == comp->pud : false)
		|| (PTRS_PER_P4D > 1 ? entry->p4d == comp->p4d : false)
		|| (PTRS_PER_PGD > 1 ? entry->pgd == comp->pgd : false));
}

bool location_has_common_IPT(struct location *entry, struct location *comp)
{
	return ((entry->pte == comp->pte)
		&& (entry->pmd == comp->pmd)
		&& (entry->pud == comp->pud)
		&& (entry->p4d == comp->p4d)
		&& (entry->pgd == comp->pgd));
}

bool location_is_in_last_entry_set(struct location *entry, struct location *array, size_t from, size_t to)
{
	/* printf("looking backward %zu %zu\n", from, to); */
	/* location_print(entry); */
	/* printf("\n"); */
	for (size_t idx = from; idx < to; idx++) {
		/* printf(" mem[%zu] ", idx); */
		/* location_print(&array[idx]); */
		/* printf("\n"); */

		if (location_has_common_IPT(entry, &array[idx])) {
			/* printf("ret true\n"); */
			return true;
		}
	}
	/* printf("ret false\n"); */
	return false;
}

/* Arrange the N elements of ARRAY in random order.
   Only effective if N is much smaller than RAND_MAX;
   if this may not be the case, use a better random
   number generator. */
void shuffle(struct location *array, size_t n)
{
	for (size_t i = 0; i < n - 1; i++) {
		size_t j = i + rand() / (RAND_MAX / (n - i) + 1);
		location_swap(&array[j], &array[i]);
	}
}

int main()
{
	srand(time(NULL));
	/* srand(1); */

	size_t memory_byte = PTRS_PER_PGD * PTRS_PER_P4D * PTRS_PER_PUD * PTRS_PER_PMD * PTRS_PER_PTE * PAGE_SIZE;
	size_t array_size = memory_byte / ELTS_SIZE;
	size_t nr_entry = memory_byte / CACHE_LINE_SIZE;
	printf("memory_byte %zu\n", memory_byte);
	printf("==> %zu B; %f KB; %f MB; %f GB\n",
	       memory_byte, (double) memory_byte / 1024.,
	       (double) memory_byte / 1024. / 1024.,
	       (double) memory_byte / 1024. / 1024. / 1024.);
	printf("nr_entry %zu\n", nr_entry);
	printf("nr_page = %zu\n", (memory_byte / PAGE_SIZE));
	printf("CACHE_LINE_PER_PAGE %zu\n", CACHE_LINE_PER_PAGE);
	/* getchar(); */

	struct location *mem = NULL;
	mem = malloc(nr_entry * sizeof(struct location));
	if (!mem)
		handle_perror("malloc");

	size_t idx_cl = 0;
	size_t idx_pte = 0;
	size_t idx_pmd = 0;
	size_t idx_pud = 0;
	size_t idx_p4d = 0;
	size_t idx_pgd = 0;

	for (size_t idx = 0; idx < nr_entry; idx++) {
		mem[idx].cl = idx_cl;
		mem[idx].pte = idx_pte;
		mem[idx].pmd = idx_pmd;
		mem[idx].pud = idx_pud;
		mem[idx].p4d = idx_p4d;
		mem[idx].pgd = idx_pgd;

		idx_cl = (idx_cl + 1) % CACHE_LINE_PER_PAGE;

		if (idx_cl == 0) {
			idx_pte = (idx_pte + 1) % PTRS_PER_PTE;
			if (idx_pte == 0) {
				idx_pmd = (idx_pmd + 1) % PTRS_PER_PMD;
				if (idx_pmd == 0) {
					idx_pud = (idx_pud + 1) % PTRS_PER_PUD;
					if (idx_pud == 0) {
						idx_p4d = (idx_p4d + 1) % PTRS_PER_P4D;
						if (idx_p4d == 0) {
							idx_pgd = (idx_pgd + 1) % PTRS_PER_PGD;
						}
					}
				}
			}
		}
	}

	size_t stride_array[2] = {1, (CACHE_LINE_SIZE / ELTS_SIZE)};
	for (size_t idx_stride = 0; idx_stride < 2; idx_stride++) {
	{
		char filename[1024];
		snprintf(filename, sizeof(filename), "sequence_%020zu_%zu_inpage.txt", array_size, stride_array[idx_stride]);

		FILE *fd_sequence = fopen(filename, "w");
		/* FILE *fd_sequence_location = fopen("sequence_location.txt", "w"); */

		fprintf(fd_sequence, "%zu %zu 1\n", array_size, stride_array[idx_stride]);

		size_t last_idx = 0;
		for (size_t idx = 0; idx < (array_size / stride_array[idx_stride]); idx++) {
			size_t next_idx = (last_idx + stride_array[idx_stride]) % array_size;

			fprintf(fd_sequence, "%zu %zu\n", last_idx, next_idx);
			/* fprintf(fd_sequence_location, "%zu %zu %zu %zu %zu %zu %zu\n", */
			/* 	idx, mem[idx].pgd, mem[idx].p4d, mem[idx].pud, mem[idx].pmd, mem[idx].pte, mem[idx].cl); */

			last_idx = next_idx;
		}

		fclose(fd_sequence);
		/* fclose(fd_sequence_location); */
	}
	}

	/* printf("before\n"); */
	/* for (size_t idx = 0; idx < nr_entry; idx++) { */
	/* 	location_print(&mem[idx]); */
	/* 	printf("\n"); */
	/* } */

	/* working inpage */
	for (size_t idx_page = 0; idx_page < (memory_byte / PAGE_SIZE); idx_page++) {
		size_t page_offset = idx_page * CACHE_LINE_PER_PAGE;
		shuffle(&mem[page_offset], CACHE_LINE_PER_PAGE);
	}

	for (size_t idx = 0; idx < nr_entry; idx++) {
		if (mem[idx].cl == 0
		    && mem[idx].pte == 0
		    && mem[idx].pmd == 0
		    && mem[idx].pud == 0
		    && mem[idx].p4d == 0
		    && mem[idx].pgd == 0) {
			location_swap(&mem[idx], &mem[0]);
			break;
		}
	}

	{
		char filename[1024];
		snprintf(filename, sizeof(filename), "sequence_%020zu_0_inpage.txt", array_size);

		FILE *fd_sequence = fopen(filename, "w");
		/* FILE *fd_sequence_location = fopen("sequence_location.txt", "w"); */

		fprintf(fd_sequence, "%zu 0 1\n", array_size);

		size_t last_idx = 0;
		for (size_t idx = nr_entry - 1; idx > 0; --idx) {
			size_t next_idx_byte = location_to_byte(&mem[idx]);
			size_t next_idx = next_idx_byte / ELTS_SIZE;

			fprintf(fd_sequence, "%zu %zu\n", last_idx, next_idx);
			/* fprintf(fd_sequence_location, "%zu %zu %zu %zu %zu %zu %zu\n", */
			/* 	idx, mem[idx].pgd, mem[idx].p4d, mem[idx].pud, mem[idx].pmd, mem[idx].pte, mem[idx].cl); */

			last_idx = next_idx;
		} {	size_t idx = 0;
			size_t next_idx_byte = location_to_byte(&mem[idx]);
			size_t next_idx = next_idx_byte / ELTS_SIZE;

			fprintf(fd_sequence, "%zu %zu\n", last_idx, next_idx);
			/* fprintf(fd_sequence_location, "%zu %zu %zu %zu %zu %zu %zu\n", */
			/*	idx, mem[idx].pgd, mem[idx].p4d, mem[idx].pud, mem[idx].pmd, mem[idx].pte, mem[idx].cl); */

			last_idx = next_idx;
		}

		fclose(fd_sequence);
		/* fclose(fd_sequence_location); */
	}



	/* working outpage */
	shuffle(mem, nr_entry);

	for (size_t idx = 0; idx < nr_entry; idx++) {
		if (mem[idx].cl == 0
		    && mem[idx].pte == 0
		    && mem[idx].pmd == 0
		    && mem[idx].pud == 0
		    && mem[idx].p4d == 0
		    && mem[idx].pgd == 0) {
			location_swap(&mem[idx], &mem[0]);
			break;
		}
	}

	/* printf("after\n"); */
	/* for (size_t idx = 0; idx < nr_entry; idx++) { */
	/*	printf("%zu ", idx); */
	/*	location_print(&mem[idx]); */
	/*	printf("\n"); */
	/* } */

	/* printf("reorder\n"); */
	size_t fail_to_swap = 0;
	for (size_t idx = 1; idx < nr_entry - 1; idx++) {
		/* printf("\nat %zu ", idx); */
		/* location_print(&mem[idx]); */
		/* printf("\n"); */
		/* getchar(); */

		size_t low_idx;
		if (__builtin_sub_overflow(idx, NR_LAST_PAGE_ENTRY_TO_AVOID, &low_idx)) {
			/* printf("overflow\n"); */
			/* getchar(); */
			low_idx = 0;
		}

		if (location_has_subset(&mem[idx], &mem[idx + 1])
		    || location_is_in_last_entry_set(&mem[idx + 1], mem, low_idx, idx)
			) {
			/* printf("should swap %zu\n", idx + 1); */
			/* printf(" == %zu ", idx + 1); */
			/* location_print(&mem[idx + 1]); */
			/* printf("\n"); */
			/* getchar(); */

			bool swaped = false;

			for (size_t idx_swap = idx + 2; idx_swap < nr_entry; idx_swap++) {
				/* printf(" candidate %zu ", idx_swap); */
				/* location_print(&mem[idx_swap]); */
				/* printf("\n"); */
				if (!location_has_subset(&mem[idx + 1], &mem[idx_swap])
				    && !location_is_in_last_entry_set(&mem[idx_swap], mem, low_idx, idx + 1)
					) {
					location_swap(&mem[idx + 1], &mem[idx_swap]);
					swaped = true;
					/* printf("found\n"); */
					break;
				}
				/* getchar(); */
			}

			if (!swaped) {
				/* printf("no candidate %zu\n", idx); */
				/* getchar(); */
				fail_to_swap++;
			}
			/* getchar(); */
		}
	}

	printf("fail_to_swap = %zu\n", fail_to_swap);

	{
		char filename[1024];
		snprintf(filename, sizeof(filename), "sequence_%020zu_0_outpage.txt", array_size);

		FILE *fd_sequence = fopen(filename, "w");
		/* FILE *fd_sequence_location = fopen("sequence_location.txt", "w"); */

		fprintf(fd_sequence, "%zu 0 0\n", array_size);

		size_t last_idx = 0;
		for (size_t idx = nr_entry - 1; idx > 0; --idx) {
			size_t next_idx_byte = location_to_byte(&mem[idx]);
			size_t next_idx = next_idx_byte / ELTS_SIZE;

			fprintf(fd_sequence, "%zu %zu\n", last_idx, next_idx);
			/* fprintf(fd_sequence_location, "%zu %zu %zu %zu %zu %zu %zu\n", */
			/* 	idx, mem[idx].pgd, mem[idx].p4d, mem[idx].pud, mem[idx].pmd, mem[idx].pte, mem[idx].cl); */

			last_idx = next_idx;
		} {	size_t idx = 0;
			size_t next_idx_byte = location_to_byte(&mem[idx]);
			size_t next_idx = next_idx_byte / ELTS_SIZE;

			fprintf(fd_sequence, "%zu %zu\n", last_idx, next_idx);
			/* fprintf(fd_sequence_location, "%zu %zu %zu %zu %zu %zu %zu\n", */
			/* 	idx, mem[idx].pgd, mem[idx].p4d, mem[idx].pud, mem[idx].pmd, mem[idx].pte, mem[idx].cl); */

			last_idx = next_idx;
		}

		fclose(fd_sequence);
		/* fclose(fd_sequence_location); */
	}
	
	printf("done\n");
	return 0;
}
