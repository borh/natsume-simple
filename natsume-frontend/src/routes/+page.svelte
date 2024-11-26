<script lang="ts">
	import Search from '../lib/Search.svelte';

	import { onMount, tick, afterUpdate } from 'svelte';
	import { writable, derived } from 'svelte/store';
	import './../tailwind.css';
	import resolveConfig from 'tailwindcss/resolveConfig';
	import tailwindConfig from '../../tailwind.config.js';

	let searchType = 'noun'; // Default searchtype

	const twFullConfig = resolveConfig(tailwindConfig);

	// Dark mode state
	const darkMode = writable(false);

	// Function to toggle dark mode
	function toggleDarkMode() {
		darkMode.update((value) => !value);
	}

	// Update the HTML class when dark mode changes
	$: if (typeof document !== 'undefined') {
		if ($darkMode) {
			document.documentElement.classList.add('dark');
		} else {
			document.documentElement.classList.remove('dark');
		}
	}

	function formatNumber(num: number): string {
		return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
	}

	type Result = {
		v: string;
		frequency: number;
		corpus: string;
		p: string;
		contributions?: { corpus: string; frequency: number }[];
	};

	type CombinedResult = {
		v: string;
		frequency: number;
		contributions: { corpus: string; frequency: number }[];
		p: string;
	};

	let apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
	let particles = ['が', 'を', 'に', 'で', 'から', 'より', 'と', 'へ'];
	let results = writable<Result[]>([]);
	let searchTerm = writable('時間');

	let lastSearchedNoun = writable('');
	let corpusNorm: Record<string, number> = {};
	let corpusSizes: string[] = [];
	let resultCount = writable(0);
	let useNormalization = writable(true);
	let selectedCorpora = writable<string[]>([]);
	let combinedSearch = writable(false);
	let searchElapsedTime = writable(0);
	let isLoading = writable(false);
	let statsDropdownOpen = false;
	let optionsDropdownOpen = false;

	const d = writable({});

	const filteredResultCount = derived([d, selectedCorpora], ([$d, $selectedCorpora]) => {
		if (!$d || Object.keys($d).length === 0) return 0;
		return Object.values($d).reduce((total, collocates) => {
			return (
				total +
				collocates.filter(
					(collocate) =>
						$selectedCorpora.includes(collocate.corpus) ||
						(collocate.contributions &&
							collocate.contributions.some((c) => $selectedCorpora.includes(c.corpus)))
				).length
			);
		}, 0);
	});

	const highlightColors = [
		twFullConfig.theme.colors.red[200],
		twFullConfig.theme.colors.purple[200],
		twFullConfig.theme.colors.green[200],
		twFullConfig.theme.colors.blue[200],
		twFullConfig.theme.colors.yellow[200],
		twFullConfig.theme.colors.pink[200]
	];

	const highlightColorsDark = [
		twFullConfig.theme.colors.red[800],
		twFullConfig.theme.colors.purple[800],
		twFullConfig.theme.colors.green[800],
		twFullConfig.theme.colors.blue[800],
		twFullConfig.theme.colors.yellow[800],
		twFullConfig.theme.colors.pink[800]
	];

	const solidColors = [
		twFullConfig.theme.colors.red[500],
		twFullConfig.theme.colors.purple[500],
		twFullConfig.theme.colors.green[500],
		twFullConfig.theme.colors.blue[500],
		twFullConfig.theme.colors.yellow[500],
		twFullConfig.theme.colors.pink[500]
	];

	function getColor(corpus: string): string {
		const index = Object.keys(corpusNorm).indexOf(corpus);
		return $darkMode
			? highlightColorsDark[index % highlightColorsDark.length]
			: highlightColors[index % highlightColors.length];
	}

	function getSolidColor(corpus: string): string {
		const index = Object.keys(corpusNorm).indexOf(corpus);
		return solidColors[index % solidColors.length];
	}

	function renderContributions(
		collocate: Result,
		collocates: (Result | CombinedResult)[],
		selectedCorpora: string[],
		useNormalization: boolean
	): Array<{ corpus: string; width: number; xOffset: number; value: number }> {
		let xOffset = 0;

		const contributions =
			collocate.contributions && collocate.contributions.length > 0
				? collocate.contributions
				: [{ corpus: collocate.corpus, frequency: collocate.frequency }];

		return contributions
			.filter(({ corpus }) => selectedCorpora.includes(corpus))
			.sort((a, b) => selectedCorpora.indexOf(a.corpus) - selectedCorpora.indexOf(b.corpus))
			.map(({ corpus, frequency }) => {
				const width =
					((frequency * (useNormalization ? corpusNorm[corpus] : 1)) /
						getMax(collocates, useNormalization)) *
					100;
				const value = useNormalization ? frequency * corpusNorm[corpus] : frequency;
				const item = { corpus, width, xOffset, value };
				xOffset += width;
				return item;
			});
	}

	$: {
		console.log('selectedCorpora changed:', $selectedCorpora);
	}

	function renderContributionsCombined(
		collocate: CombinedResult,
		collocates: (Result | CombinedResult)[],
		selectedCorpora: string[],
		useNormalization: boolean
	): Array<{ corpus: string; width: number; xOffset: number; value: number }> {
		let xOffset = 0;
		return collocate.contributions
			.filter(({ corpus }) => selectedCorpora.includes(corpus))
			.sort((a, b) => selectedCorpora.indexOf(a.corpus) - selectedCorpora.indexOf(b.corpus))
			.map(({ corpus, frequency }) => {
				const width =
					((frequency * (useNormalization ? corpusNorm[corpus] : 1)) /
						getMax(collocates, useNormalization)) *
					100;
				const value = useNormalization ? frequency * corpusNorm[corpus] : frequency;
				const result = { corpus, width, xOffset, value };
				xOffset += width;
				return result;
			});
	}

	function calculateCorpusDistribution(
		collocates: (Result | CombinedResult)[],
		useNormalization: boolean,
		corpusNorm: Record<string, number>
	): Record<string, number> {
		console.log('Calculating corpus distribution', collocates);
		const distribution: Record<string, number> = {};
		collocates.forEach((collocate) => {
			if (collocate.contributions && collocate.contributions.length > 0) {
				// Combined search mode
				collocate.contributions.forEach(
					({ corpus, frequency }: { corpus: string; frequency: number }) => {
						distribution[corpus] =
							(distribution[corpus] || 0) +
							frequency * (useNormalization && corpusNorm[corpus] ? corpusNorm[corpus] : 1);
					}
				);
			} else if ('corpus' in collocate) {
				// Non-combined search mode
				const corpus = collocate.corpus;
				distribution[corpus] =
					(distribution[corpus] || 0) +
					collocate.frequency * (useNormalization && corpusNorm[corpus] ? corpusNorm[corpus] : 1);
			}
		});
		console.log('Corpus distribution result:', distribution);
		return distribution;
	}

	function ParticleHeader({
		particle,
		collocates,
		maxFrequency,
		useNormalization,
		corpusNorm,
		totalFrequency,
		selectedCorpora
	}: {
		particle: string;
		collocates: (Result | CombinedResult)[];
		maxFrequency: number;
		useNormalization: boolean;
		corpusNorm: Record<string, number>;
		totalFrequency: number;
		selectedCorpora: string[];
	}) {
		console.log('ParticleHeader called with:', { particle, collocates, selectedCorpora });
		const distribution = calculateCorpusDistribution(collocates, useNormalization, corpusNorm);
		const particleTotal = Object.values(distribution).reduce((sum, value) => sum + value, 0);

		let cumulativeFrequency = 0;
		const distributionWithOffsets = Object.entries(distribution)
			.filter(([corpus]) => selectedCorpora.includes(corpus))
			.map(([corpus, frequency]) => {
				const width = totalFrequency > 0 ? (frequency / totalFrequency) * 100 : 0;
				const xOffset = totalFrequency > 0 ? (cumulativeFrequency / totalFrequency) * 100 : 0;
				cumulativeFrequency += frequency;
				return { corpus, frequency, width, xOffset };
			});

		console.log('ParticleHeader result:', {
			particle,
			distribution,
			particleTotal,
			distributionWithOffsets
		});
		return {
			particle,
			distribution,
			particleTotal,
			distributionWithOffsets,
			maxFrequency
		};
	}

	onMount(() => {
		const fetchData = async () => {
			try {
				const response = await fetch(`${apiUrl}/corpus/norm`);
				corpusNorm = await response.json();
				corpusSizes = Object.entries(corpusNorm).map(
					([corpus, size]) => `${corpus}: ${size.toFixed(2)}`
				);
				selectedCorpora.set(Object.keys(corpusNorm));

				// Call getNPVs to fetch initial data
				await performSearch();
			} catch (error) {
				console.error('Error fetching corpus norm:', error);
			}

			updateScrollButtonsVisibility();
		};

		fetchData();

		window.addEventListener('resize', updateScrollButtonsVisibility);
		window.addEventListener('scroll', updateScrollButtonsVisibility);

		if (mainScrollContainer) {
			console.log('Main scroll container properties:');
			console.log('scrollWidth:', mainScrollContainer.scrollWidth);
			console.log('clientWidth:', mainScrollContainer.clientWidth);
			console.log('offsetWidth:', mainScrollContainer.offsetWidth);
			console.log('style.overflowX:', mainScrollContainer.style.overflowX);
		}

		return () => {
			window.removeEventListener('resize', updateScrollButtonsVisibility);
			window.removeEventListener('scroll', updateScrollButtonsVisibility);
		};
	});

	function computeDerivedData(
		results: Result[],
		useNormalization: boolean,
		selectedCorpora: string[],
		combinedSearch: boolean
	) {
		console.log('Computing derived data');
		let derivedData;
		if (combinedSearch) {
			// Combine results across all particles first
			const combinedResults = results.reduce<Record<string, CombinedResult>>((acc, curr) => {
				if (selectedCorpora.includes(curr.corpus as string)) {
					const key = `${curr.v}-${curr.p}`; // Use both verb and particle as key
					if (!acc[key]) {
						acc[key] = { v: curr.v, p: curr.p, frequency: 0, contributions: [] };
					}
					acc[key].frequency += curr.frequency * (useNormalization ? corpusNorm[curr.corpus] : 1);
					acc[key].contributions.push({
						corpus: curr.corpus as string,
						frequency: curr.frequency
					});
				}
				return acc;
			}, {});

			// Then separate by particle
			derivedData = Object.fromEntries(
				particles.map((particle) => [
					particle,
					Object.values(combinedResults)
						.filter((d: CombinedResult) => d.p === particle)
						.sort((a, b) => b.frequency - a.frequency)
				])
			);
		} else {
			// Non-combined logic remains the same
			derivedData = Object.fromEntries(
				particles.map((particle) => [
					particle,
					results
						.filter(
							(d: { p: string; corpus: string }) =>
								d.p === particle && selectedCorpora.includes(d.corpus)
						)
						.map((d: Result) => ({ ...d, contributions: d.contributions || [] }))
						.sort((a: Result, b: Result): number => {
							const aValue = a.frequency * (useNormalization ? corpusNorm[a.corpus] : 1);
							const bValue = b.frequency * (useNormalization ? corpusNorm[b.corpus] : 1);
							return bValue - aValue;
						})
				])
			);
		}
		return derivedData;
	}

	async function updateDerivedData() {
		const derivedData = computeDerivedData(
			$results,
			$useNormalization,
			$selectedCorpora,
			$combinedSearch
		);
		d.set(derivedData);
		await tick(); // Wait for the next DOM update
	}

	async function handleCheckboxChange() {
		isLoading.set(true);
		await updateDerivedData();
		isLoading.set(false);
	}

	async function performSearch(): Promise<void> {
		try {
			isLoading.set(true); // Set loading state
			const startTime = performance.now();

			// Construct API endpoint based on search type
			const endpoint =
				searchType === 'verb' ? `/npv/verb/${$searchTerm}` : `/npv/noun/${$searchTerm}`;
			const response = await fetch(`${apiUrl}${endpoint}`);
			const data = await response.json();

			const endTime = performance.now();
			searchElapsedTime.set((endTime - startTime) / 1000); // Calculate elapsed time
			results.set(data as Result[]);
			resultCount.set(data.length);
			lastSearchedNoun.set($searchTerm); // Update the last searched term

			await updateDerivedData(); // Update derived data
		} catch (error) {
			console.error('Error fetching results:', error);
		} finally {
			isLoading.set(false); // Turn off loading state
		}
	}

	function getMax(collocates: (Result | CombinedResult)[], useNormalization: boolean): number {
		return Math.max(
			...collocates.map((x) => {
				if (x.contributions && x.contributions.length > 0) {
					return Math.max(
						...x.contributions.map(
							(c) => c.frequency * (useNormalization ? corpusNorm[c.corpus] : 1)
						)
					);
				} else {
					return x.frequency * (useNormalization && 'corpus' in x ? corpusNorm[x.corpus] : 1);
				}
			}),
			0.0
		);
	}

	function showTooltip(event: { pageX: number; pageY: number }, text: string | null) {
		const tooltip = document.getElementById('tooltip');
		if (tooltip) {
			tooltip.textContent = text;
			tooltip.style.left = `${event.pageX + 10}px`;
			tooltip.style.top = `${event.pageY + 10}px`;
			tooltip.classList.remove('hidden');
		}
	}

	function hideTooltip() {
		const tooltip = document.getElementById('tooltip');
		if (tooltip) {
			tooltip.classList.add('hidden');
		}
	}

	function tooltipAction(
		node: HTMLLIElement,
		{
			getTooltipData,
			useNormalization
		}: { getTooltipData: () => Record<string, number>; useNormalization: boolean }
	) {
		const handleMouseover = (event: any) => {
			const tooltipData = getTooltipData();
			const tooltipText = Object.entries(tooltipData)
				.map(([corpus, value]) => {
					const formattedValue = useNormalization ? value.toFixed(2) : Math.round(value).toString();
					return `${corpus}: ${formattedValue}`;
				})
				.join(', ');
			showTooltip(event, tooltipText);
		};
		const handleMouseout = hideTooltip;

		node.addEventListener('mouseover', handleMouseover);
		node.addEventListener('mouseout', handleMouseout);

		return {
			destroy() {
				node.removeEventListener('mouseover', handleMouseover);
				node.removeEventListener('mouseout', handleMouseout);
			}
		};
	}

	const columnWidth = 200; // Set a fixed width for all columns
	const columnSpacing = 4; // Set a fixed spacing between columns

	let headerScrollContainer: HTMLElement;
	let mainScrollContainer: HTMLElement;

	function syncScroll(event: Event) {
		const scrollingElement = event.target as HTMLElement;
		if (scrollingElement === headerScrollContainer) {
			mainScrollContainer.scrollLeft = scrollingElement.scrollLeft;
		} else if (scrollingElement === mainScrollContainer) {
			headerScrollContainer.scrollLeft = scrollingElement.scrollLeft;
		}
	}

	function scrollOneColumn(direction: 'left' | 'right') {
		console.log(`Scrolling ${direction}`);
		if (mainScrollContainer) {
			const currentScroll = mainScrollContainer.scrollLeft;
			const scrollAmount = columnWidth + columnSpacing;
			const newScroll =
				direction === 'left'
					? Math.max(0, currentScroll - scrollAmount)
					: currentScroll + scrollAmount;

			console.log(`Before scroll - Current scroll: ${currentScroll}, Target scroll: ${newScroll}`);

			requestAnimationFrame(() => {
				mainScrollContainer.scrollLeft = newScroll;

				// Force a reflow to ensure the scroll has been applied
				void mainScrollContainer.offsetWidth;

				console.log(`After scroll - New scroll position: ${mainScrollContainer.scrollLeft}`);
			});
		} else {
			console.log('mainScrollContainer is not defined');
		}
	}

	function updateScrollButtonsVisibility() {
		if (mainScrollContainer) {
			const hasOverflow = mainScrollContainer.scrollWidth > mainScrollContainer.clientWidth;
			const leftButton = document.querySelector('.left-button') as HTMLElement;
			const rightButton = document.querySelector('.right-button') as HTMLElement;

			if (leftButton && rightButton) {
				const scrollLeft = mainScrollContainer.scrollLeft;
				const maxScrollLeft = mainScrollContainer.scrollWidth - mainScrollContainer.clientWidth;

				const containerRect = mainScrollContainer.getBoundingClientRect();
				const viewportHeight = window.innerHeight;
				const containerVisibleTop = Math.max(0, containerRect.top);
				const containerVisibleBottom = Math.min(viewportHeight, containerRect.bottom);
				const visibleCenterY =
					containerVisibleTop + (containerVisibleBottom - containerVisibleTop) / 2;

				leftButton.style.display = hasOverflow && scrollLeft > 0 ? 'flex' : 'none';
				rightButton.style.display = hasOverflow && scrollLeft < maxScrollLeft ? 'flex' : 'none';

				// Adjust the top position to account for both sticky headers
				const topHeader = document.querySelector('header:first-of-type');
				const particlesHeader = document.querySelector('header:nth-of-type(2)');
				const totalHeaderHeight =
					(topHeader?.clientHeight || 0) + (particlesHeader?.clientHeight || 0);
				const buttonTop = Math.max(visibleCenterY, totalHeaderHeight + 20); // 20px padding

				leftButton.style.top = `${buttonTop}px`;
				rightButton.style.top = `${buttonTop}px`;
			}
		}
	}

	function handleClickOutside(event: MouseEvent) {
		const statsDropdown = document.querySelector('#stats-dropdown');
		const optionsDropdown = document.querySelector('#options-dropdown');
		const statsButton = document.querySelector('#stats-button');
		const optionsButton = document.querySelector('#options-button');

		if (
			statsDropdown &&
			!statsDropdown.contains(event.target as Node) &&
			!statsButton?.contains(event.target as Node)
		) {
			statsDropdownOpen = false;
		}
		if (
			optionsDropdown &&
			!optionsDropdown.contains(event.target as Node) &&
			!optionsButton?.contains(event.target as Node)
		) {
			optionsDropdownOpen = false;
		}
	}

	afterUpdate(() => {
		updateScrollButtonsVisibility();
	});
</script>

<div class="flex flex-col min-h-screen bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
	<!-- Fixed top header with search bar and info dropdown -->
	<header
		class="fixed top-0 left-0 right-0 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 p-2 z-20"
	>
		<div class="container mx-auto flex flex-wrap justify-between items-center">
			<h1 class="text-xl text-red-600 dark:text-red-400 font-bold mr-4">Natsuma Komima Simple</h1>
			<div class="flex-1 flex justify-center items-center space-x-2">
				<Search {searchTerm} {performSearch} {isLoading} />
			</div>
			<div class="relative inline-block text-left">
				<div class="flex space-x-2">
					<button
						id="stats-button"
						class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-1 px-2 rounded inline-flex items-center text-sm dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-gray-200"
						on:click={() => (statsDropdownOpen = !statsDropdownOpen)}
					>
						<span>Stats</span>
						<svg
							class="fill-current h-4 w-4 ml-1"
							xmlns="http://www.w3.org/2000/svg"
							viewBox="0 0 20 20"
						>
							<path
								d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"
							/>
						</svg>
					</button>
					<button
						id="options-button"
						class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-1 px-2 rounded inline-flex items-center text-sm dark:bg-gray-700 dark:hover:bg-gray-600 dark:text-gray-200"
						on:click={() => (optionsDropdownOpen = !optionsDropdownOpen)}
					>
						<span>Options</span>
						<svg
							class="fill-current h-4 w-4 ml-1"
							xmlns="http://www.w3.org/2000/svg"
							viewBox="0 0 20 20"
						>
							<path
								d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z"
							/>
						</svg>
					</button>
				</div>
				{#if statsDropdownOpen}
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
				{/if}

				{#if optionsDropdownOpen}
					<div
						id="options-dropdown"
						class="origin-top-right absolute right-0 mt-2 w-64 rounded-md shadow-lg bg-white dark:bg-gray-800 ring-1 ring-black ring-opacity-5 focus:outline-none z-30"
					>
						<div class="py-1">
							<!-- Existing Options -->
							<div class="px-4 py-2">
								<label class="flex items-center mb-2">
									<input
										type="checkbox"
										id="use-normalization"
										name="use-normalization"
										checked={$useNormalization}
										on:change={() => {
											$useNormalization = !$useNormalization;
											handleCheckboxChange();
										}}
										class="mr-2"
									/>
									<span class="dark:text-gray-300">Use Corpus Normalization</span>
								</label>
								<label class="flex items-center mb-2">
									<input
										type="checkbox"
										id="combined-search"
										name="combined-search"
										checked={$combinedSearch}
										on:change={() => {
											$combinedSearch = !$combinedSearch;
											handleCheckboxChange();
										}}
										class="mr-2"
									/>
									<span class="dark:text-gray-300">Combined Search</span>
								</label>
								<div class="mt-2">
									<span class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
										>Corpus Selection</span
									>
									{#each Object.keys(corpusNorm) as corpus}
										<label
											class="flex items-center mb-2 px-2 py-1 rounded border-2"
											style="border-color: {getSolidColor(corpus)}; background-color: {getColor(
												corpus
											)}"
										>
											<input
												type="checkbox"
												id="corpus-{corpus}"
												name="corpus-{corpus}"
												bind:group={$selectedCorpora}
												value={corpus}
												on:change={handleCheckboxChange}
												class="mr-2"
											/>
											<span class="dark:text-white">{corpus}</span>
										</label>
									{/each}
								</div>
							</div>
						</div>
					</div>
				{/if}
			</div>
			<button
				class="ml-2 p-1 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-white"
				on:click={toggleDarkMode}
			>
				{#if $darkMode}
					<svg
						class="w-6 h-6 text-yellow-300"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
						xmlns="http://www.w3.org/2000/svg"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
						></path>
					</svg>
				{:else}
					<svg
						class="w-6 h-6 text-gray-800"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
						xmlns="http://www.w3.org/2000/svg"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
						></path>
					</svg>
				{/if}
			</button>
		</div>
	</header>

	<!-- Sticky particles header -->
	<header
		class="sticky top-12 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 z-10"
	>
		<div
			class="container mx-auto p-0 overflow-x-auto hide-scrollbar"
			bind:this={headerScrollContainer}
			on:scroll={syncScroll}
		>
			<div class="flex" style="gap: {columnSpacing}px;">
				{#if $d && Object.keys($d).length > 0}
					{#each Object.entries($d) as [particle, collocates]}
						{#if collocates && collocates.length > 0}
							<div style="width: {columnWidth}px; flex-shrink: 0;">
								<h2 class="text-center text-2xl font-semibold">{particle}</h2>
								<div class="h-1 w-full relative">
									{#each ParticleHeader( { particle, collocates, maxFrequency: getMax(collocates, $useNormalization), useNormalization: $useNormalization, corpusNorm, totalFrequency: collocates.reduce((sum, c) => sum + c.frequency, 0), selectedCorpora: $selectedCorpora } ).distributionWithOffsets as { corpus, width, xOffset }}
										<div
											class="absolute h-full"
											style="left: {xOffset}%; width: {width}%; background-color: {getSolidColor(
												corpus
											)};"
										></div>
									{/each}
								</div>
							</div>
						{/if}
					{/each}
				{/if}
			</div>
		</div>
	</header>

	<!-- Main content area -->
	<main class="flex-1 overflow-y-auto pt-12">
		<div class="container mx-auto p-0">
			<div class="relative">
				<button class="scroll-button left-button" on:click={() => scrollOneColumn('left')}>
					<span class="arrow">←</span>
				</button>
				<div
					class="overflow-x-auto"
					bind:this={mainScrollContainer}
					on:scroll={syncScroll}
					style="width: 100%; max-width: 100vw;"
				>
					<div class="flex" style="gap: {columnSpacing}px;">
						{#if $d && Object.keys($d).length > 0}
							{#each Object.entries($d) as [particle, collocates]}
								{#if collocates && collocates.length > 0}
									<div style="width: {columnWidth}px; flex-shrink: 0;">
										<ul class="list-none p-0 space-y-0 mt-2">
											{#each collocates as collocate}
												<li
													class="flex items-center mb-0.5 justify-start p-0"
													style="background-color: {$combinedSearch
														? 'transparent'
														: getColor(collocate.corpus)}"
													use:tooltipAction={{
														getTooltipData: () => {
															const tooltipData: Record<string, number> = {};
															if ($combinedSearch) {
																collocate.contributions.forEach(
																	({
																		corpus,
																		frequency
																	}: {
																		corpus: string;
																		frequency: number;
																	}) => {
																		tooltipData[corpus] = $useNormalization
																			? frequency * corpusNorm[corpus]
																			: frequency;
																	}
																);
															} else {
																tooltipData[collocate.corpus] = $useNormalization
																	? collocate.frequency * corpusNorm[collocate.corpus]
																	: collocate.frequency;
															}
															return tooltipData;
														},
														useNormalization: $useNormalization
													}}
												>
													<svg width="50" height="20" class="mr-2">
														{#if !$combinedSearch}
															{#each renderContributions(collocate, collocates, $selectedCorpora, $useNormalization) as { corpus, width, xOffset, value }}
																<rect
																	style="fill: {getSolidColor(corpus)}"
																	height="20"
																	width="{width}%"
																	x="{xOffset}%"
																/>
															{/each}
														{:else}
															{#each renderContributionsCombined(collocate, collocates, $selectedCorpora, $useNormalization) as { corpus, width, xOffset, value }}
																<rect
																	style="fill: {getSolidColor(corpus)}"
																	height="20"
																	width="{width}%"
																	x="{xOffset}%"
																/>
															{/each}
														{/if}
													</svg>
													<span class="text-left font-medium">{collocate.n}{collocate.v}</span>
													{#if !$combinedSearch}
														<span class="text-sm text-gray-600 dark:text-gray-200 ml-2 text-left"
															>{collocate.corpus}</span
														>
													{/if}
												</li>
											{/each}
										</ul>
									</div>
								{/if}
							{/each}
						{:else}
							<p class="text-center text-gray-600 mt-4">
								{#if $results.length > 0}
									Showing results for {searchType === 'verb' ? 'Verb' : 'Noun'}: "{$searchTerm}"
								{:else}
									No results found for {searchType === 'verb' ? 'Verb' : 'Noun'}: "{$searchTerm}"
								{/if}
							</p>
						{/if}
					</div>
				</div>
				<button class="scroll-button right-button" on:click={() => scrollOneColumn('right')}>
					<span class="arrow">→</span>
				</button>
			</div>
		</div>
	</main>
</div>

{#if $isLoading}
	<div
		class="fixed inset-0 bg-black bg-opacity-50 dark:bg-opacity-70 flex items-center justify-center z-50"
	>
		<div class="bg-white dark:bg-gray-800 p-4 rounded-lg">
			<p class="text-lg font-semibold dark:text-white">Loading...</p>
		</div>
	</div>
{/if}

<div
	id="tooltip"
	class="hidden absolute bg-gray-700 dark:bg-gray-200 text-white dark:text-gray-800 text-sm p-2 rounded"
></div>

<svelte:window on:click={handleClickOutside} />

<style>
	#tooltip {
		pointer-events: none;
		z-index: 20;
	}

	.scroll-button {
		position: fixed;
		width: 30px;
		height: 30px;
		background-color: rgba(0, 0, 0, 0.5);
		color: white;
		border: none;
		border-radius: 50%;
		display: none;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		z-index: 10;
		transition: background-color 0.3s ease;
	}

	.scroll-button:hover {
		background-color: rgba(0, 0, 0, 0.7);
	}

	.left-button {
		left: 10px;
	}

	.right-button {
		right: 10px;
	}

	.arrow {
		font-size: 18px;
		line-height: 1;
	}

	.hide-scrollbar {
		-ms-overflow-style: none; /* IE and Edge */
		scrollbar-width: none; /* Firefox */
	}
	.hide-scrollbar::-webkit-scrollbar {
		display: none; /* Chrome, Safari and Opera */
	}

	.overflow-x-auto {
		overflow-x: auto !important;
		-webkit-overflow-scrolling: touch;
	}

	.relative {
		position: relative;
	}

	#stats-dropdown,
	#options-dropdown {
		max-height: calc(100vh - 100px);
		overflow-y: auto;
	}
</style>
