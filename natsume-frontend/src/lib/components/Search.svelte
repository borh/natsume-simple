<script lang="ts">
import pkg from "lodash";
import { onMount } from "svelte";
import type { Writable } from "svelte/store";
import { writable } from "svelte/store";
import EosIconsLoading from "~icons/eos-icons/loading";
import MaterialSymbolsSearch from "~icons/material-symbols/search";

const { debounce } = pkg;

let {
	searchTerm = $bindable(""),
	searchType = $bindable<"verb" | "noun">("verb"),
	performSearch = () => {},
	isLoading = false,
} = $props();

// Reactive stores
const suggestions = writable<Array<{ word: string; pos: string }>>([]);
const showSuggestions = writable(false);

const apiUrl = import.meta.env.VITE_API_URL || "http://localhost:8000";
// Debounced search function，delay 300ms
const debouncedFetchSuggestions = debounce(fetchSuggestions, 300);
async function fetchSuggestions(query: string) {
	if (query.length === 0) {
		suggestions.set([]);
		showSuggestions.set(false);
		return;
	}
	try {
		const response = await fetch(
			`${apiUrl}/search/${encodeURIComponent(query)}`,
		);
		const data = await response.json();

		// Filter the proper part of speech
		const filteredSuggestions = data
			.filter((item: [string, string]) => {
				const [word, pos] = item;
				return pos === (searchType === "noun" ? "n" : "v");
			})
			.slice(0, 10) // Top 10 outcomes
			.map((item: [string, string]) => {
				const [word, pos] = item;
				return { word, pos };
			});
		suggestions.set(filteredSuggestions);
		showSuggestions.set(filteredSuggestions.length > 0);
	} catch (error) {
		console.error("Error fetching suggestions:", error);
		showSuggestions.set(false);
	}
}

$effect(() => {
	debouncedFetchSuggestions(searchTerm);
});

let containerElement: HTMLDivElement;

function handleClickOutside(event: MouseEvent) {
	if (!containerElement.contains(event.target as Node)) {
		showSuggestions.set(false);
	}
}

onMount(() => {
	document.addEventListener("click", handleClickOutside);
	return () => {
		document.removeEventListener("click", handleClickOutside);
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
		onkeypress={(e) => {
			if (e.key === 'Enter') {
				performSearch();
				showSuggestions.set(false); // hide suggested word
			}
		}}
		placeholder={searchType === 'verb' ? 'Search Verb' : 'Search Noun'}
		autocomplete="off"
	/>

	{#if $showSuggestions}
		<ul class="suggestions-list">
			{#each $suggestions as suggestion}
				<li
					class="suggestion-item"
					onclick={() => {
						searchTerm = suggestion.word;
						showSuggestions.set(false);
						performSearch();
					}}
				>
					{suggestion.word}
				</li>
			{/each}
		</ul>
	{/if}

	<button
		class="bg-red-700 hover:bg-red-500 text-white font-bold py-1 px-2 rounded h-8 text-sm dark:bg-red-600 dark:hover:bg-red-500"
		onclick={() => performSearch()}
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
		top: 100%;
		left: 0;
		background-color: white;
		border: 1px solid #ccc;
		max-height: 200px;
		overflow-y: auto;
		width: auto;
		min-width: 100%;
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
