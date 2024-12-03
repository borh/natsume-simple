<script lang="ts">
	import MaterialSymbolsSearch from '~icons/material-symbols/search';
	import EosIconsLoading from '~icons/eos-icons/loading';
	import type { Writable } from 'svelte/store';
	import { onMount } from 'svelte';
	import pkg from 'lodash';

	const { debounce } = pkg;

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

	let suggestions: Array<{ word: string; pos: string }> = [];
	let showSuggestions = false;
	let apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
	// Debounced search function，delay 300ms
	const debouncedFetchSuggestions = debounce(fetchSuggestions, 300);
	async function fetchSuggestions(query: string) {
		if (query.length === 0) {
			suggestions = [];
			showSuggestions = false;
			return;
		}
		try {
			const response = await fetch(`${apiUrl}/search/${encodeURIComponent(query)}`);
			const data = await response.json();

			// Filter the proper part of speech
			suggestions = data
				.filter((item: [string, string]) => {
					const [word, pos] = item;
					return pos === (searchType === 'noun' ? 'n' : 'v');
				})
				.slice(0, 10) // Top 10 outcomes
				.map((item: [string, string]) => {
					const [word, pos] = item;
					return { word, pos };
				});
			console.log(suggestions);
			showSuggestions = suggestions.length > 0;
			console.log(showSuggestions);
		} catch (error) {
			console.error('Error fetching suggestions:', error);
			suggestions = [];
			showSuggestions = false;
		}
	}

	let containerElement: HTMLDivElement;

	function handleClickOutside(event: MouseEvent) {
		if (!containerElement.contains(event.target as Node)) {
			showSuggestions = false;
		}
	}

	onMount(() => {
		document.addEventListener('click', handleClickOutside);
		return () => {
			document.removeEventListener('click', handleClickOutside);
		};
	});
</script>

<div class="flex items-center space-x-1 relative" bind:this={containerElement}>
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
		oninput={(e) => {
			console.log(e);
			searchTerm = e.currentTarget.value;
			debouncedFetchSuggestions(searchTerm);
		}}
		onkeypress={(e) => {
			if (e.key === 'Enter') {
				performSearch();
				showSuggestions = false; // hide suggested word
			}
		}}
		placeholder={searchType === 'verb' ? 'Search Verb' : 'Search Noun'}
		autocomplete="off"
	/>

	{#if showSuggestions}
		<ul class="suggestions-list">
			{#each suggestions as suggestion}
				<li
					class="suggestion-item"
					onclick={() => {
						searchTerm = suggestion.word;
						showSuggestions = false;
						performSearch(); // optional: execute searching automatically
					}}
				>
					{suggestion.word}
				</li>
			{/each}
		</ul>
	{/if}

	<button
		class="bg-red-700 hover:bg-red-500 text-white font-bold py-1 px-2 rounded h-8 text-sm dark:bg-red-600 dark:hover:bg-red-500"
		onclick={performSearch}
		disabled={isLoading}
	>
		{#if isLoading}
			<EosIconsLoading />
		{:else}
			<MaterialSymbolsSearch />
		{/if}
	</button>
</div>

<style>
	.suggestions-list {
		position: absolute;
		background-color: white;
		border: 1px solid #ccc;
		max-height: 200px;
		overflow-y: auto;
		width: 100%;
		z-index: 1000;
	}

	.suggestion-item {
		padding: 8px;
		cursor: pointer;
	}

	.suggestion-item:hover {
		background-color: #f0f0f0;
	}

	/* dark mode */
	.dark .suggestions-list {
		background-color: #2d2d2d;
		color: white;
	}

	.dark .suggestion-item:hover {
		background-color: #3d3d3d;
	}
</style>
