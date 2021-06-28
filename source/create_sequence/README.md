# create_sequence

This program is used to generate a sequence for `microbe_cache`.

In the source code of the sequence generator, you can specify `CACHE_LINE_SIZE` and `PAGE_SIZE` which are dependent on the system (`getconf LEVEL1_DCACHE_LINESIZE` and `getconf PAGE_SIZE` to obtain them). `SIZE_T_BASE_TYPE` is the type behind `size_t` of the targeted machine.
Also, you can specify `PTRS_PER_{PGD,P4D,PUD,PMD,PTE}` to setup the size of the array you would like to play with. These refers to the numbers of entry per intermediate table to translate memory addresses from virtual to physical. Under Linux, these are specified in `https://elixir.bootlin.com/linux/latest/source/arch/<your architecture>/include/asm/pgtable.h`.
For arm 32bits (with and without LPAE) and arm 64bits, these are already specified in comments.

Multiple files of the form `sequence_<array size>_<cache line stride>_<page stride>.bin` are generated:
* where cache line stride = 1, page stride = 1: a sequence that access the direct next index in the array.
* cache line stride = <CACHE_LINE_SIZE / sizeof(size_t)>, page stride = 1: a sequence that access the array by cache line linearly.
* cache line stride = 0, page stride = 1: a sequence that jumps randomly within a memory page. When all cache lines are accessed once, it passes to the next page. This sequence is usefull to force regular cache misses. The sequence are likely to be not prefetchable.
* cache line stride = 0, page stride = 0: is a sequence that jumps randomly in the array. Each access try to touch a different set of {PGD,P4D,PUD,PMD,PTE,CL}, and to avoid the last `NR_LAST_PAGE_ENTRY_TO_AVOID` translation. This sequence tries to stress the TLB.

For cache line stride = 0, page stride = 0, the current constraints between two memory access is as:
* next->{pgd, p4d, pud, pmd, pte, cl} != last->{pgd, p4d, pud, pmd, pte, cl}
* next->{pgd, p4d, pud, pmd, pte} != last->{pgd, p4d, pud, pmd, pte} on the last `NR_LAST_PAGE_ENTRY_TO_AVOID` entry.

These two constraints should force a page walk depending on the array_size and `NR_LAST_PAGE_ENTRY_TO_AVOID`.

## TODO
* avoid linearity on `N` consecutive access to avoid "naive" prefetachability at TLB level.
* avoid partial intermediate LX-level translation to minimise intermediate page table caching.
