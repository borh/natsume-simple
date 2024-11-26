<script>
	let { corpusNorm, filteredResultCount, searchElapsedTime, formatNumber } = $props();
</script>

<div
	id="stats-dropdown"
	class="origin-top-right absolute right-0 mt-2 w-64 rounded-md shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5 focus:outline-none z-30"
>
	<div class="py-1">
		<!-- Corpus Sizes -->
		<div class="px-4 py-2">
			<h2 class="text-lg font-semibold mb-2 dark:text-gray-200">Corpus Sizes</h2>
			<ul class="list-none p-0 space-y-1 dark:text-gray-300">
				{#each Object.entries(corpusNorm) as [corpus, ratio]}
					{@const rawCount = Math.round(ratio * 1000000)}
					<li>{corpus}: {formatNumber(rawCount)} ({ratio.toFixed(2)})</li>
				{/each}
			</ul>
		</div>
		<!-- Search Results Info -->
		<div class="px-4 py-2 border-t border-gray-200 dark:border-gray-700">
			<h2 class="text-lg font-semibold mb-2 dark:text-gray-200">Search Results</h2>
			<p class="dark:text-gray-300">Collocations found: {$filteredResultCount}</p>
			<p class="dark:text-gray-300">
				Search time: {$searchElapsedTime.toFixed(2)} seconds
			</p>
		</div>
	</div>
</div>
