<script lang="ts">
	import type { Writable } from 'svelte/store';

	let {
		searchType = $bindable(),
		searchTerm = $bindable(),
		performSearch,
		isLoading
	}: {
		searchType: 'verb' | 'noun';
		searchTerm: string;
		performSearch: () => void;
		isLoading: boolean;
	} = $props();
</script>

<div class="flex items-center space-x-1">
	<!-- Select searching pattern -->
	<select
		class="border rounded h-8 dark:bg-gray-700 dark:text-white dark:border-gray-600"
		bind:value={searchType}
	>
		<option value="verb">Verb(Noun-Particle-Verb)</option>
		<option value="noun">Noun(Noun-Particle-Verb)</option>
	</select>
	<input
		class="text-lg p-1 border rounded mr-2 h-8 w-40 sm:w-auto dark:bg-gray-700 dark:text-white dark:border-gray-600"
		id="search-input"
		name="search-input"
		bind:value={searchTerm}
		onkeypress={(e) => {
			if (e.key === 'Enter') performSearch();
		}}
		placeholder={searchType === 'verb' ? 'Search Verb' : 'Search Noun'}
	/>
	<button
		class="bg-red-700 hover:bg-red-500 text-white font-bold py-1 px-2 rounded h-8 text-sm dark:bg-red-600 dark:hover:bg-red-500"
		onclick={performSearch}
		disabled={isLoading}
	>
		{isLoading ? 'Searching...' : 'Search'}
	</button>
</div>
