<script lang="ts">
  import { onMount } from 'svelte';

  let apiUrl = "http://127.0.0.1:8000";
  let particles = ["が", "を", "に", "で", "から", "より", "と", "へ"];
  let results = $state([]);
  let noun = $state("時間");
  let corpusNorm = $state({});

  onMount(async () => {
    try {
      const response = await fetch(`${apiUrl}/corpus/norm/`);
      corpusNorm = await response.json();
    } catch (error) {
      console.error("Error fetching corpus norm:", error);
    }
  });

  async function getNPVs() {
    try {
      const response = await fetch(`${apiUrl}/npv/noun/${noun}`);
      results = await response.json();
    } catch (error) {
      console.error("Error fetching NPVs:", error);
    }
  }

  let d = $derived(() => Object.fromEntries(
    particles.map((particle) => [
      particle,
      results.filter((d) => d.p == particle)
    ])
  ));

  function getMax(collocates) {
    return Math.max(...collocates.map((x) => x.frequency), 0.0);
  }
</script>

<main>
  <h1>Natsume Simple Search</h1>
  <label>
    検索語：
    <input
      bind:value={noun}
      onchange={getNPVs}
      onkeypress={(e) => {
        if (e.key === 'Enter') getNPVs();
      }}
    />
  </label>
  <div class="columns">
    {#each Object.entries(d) as [particle, collocates]}
      <div class="particle-column">
        <h2>{particle}</h2>
        <ul>
          {#each collocates as { v, frequency, corpus }}
            <li>
              <svg width="100" height="20">
                <rect
                  fill="hotpink"
                  height="20"
                  width={((frequency * corpusNorm[corpus]) / getMax(collocates)) * 100}
                />
              </svg>
              <span>{v}</span>
              <span class="corpus">{corpus}</span>
            </li>
          {/each}
        </ul>
      </div>
    {/each}
  </div>
</main>

<style>
  :global(body) {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }

  main {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }

  h1 {
    color: #ff3e00;
    text-align: center;
    font-size: 2.5em;
    margin-bottom: 1rem;
  }

  label {
    display: block;
    margin-bottom: 1rem;
    text-align: center;
  }

  input {
    font-size: 1rem;
    padding: 0.5rem;
  }

  .columns {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-around;
  }

  .particle-column {
    flex: 1;
    min-width: 200px;
    margin: 0 1rem 1rem 0;
  }

  h2 {
    text-align: center;
    font-size: 1.5em;
    margin-bottom: 0.5rem;
  }

  ul {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  li {
    display: flex;
    align-items: center;
    margin-bottom: 0.25rem;
  }

  svg {
    margin-right: 0.5rem;
  }

  .corpus {
    font-size: 0.8em;
    color: #666;
    margin-left: 0.5rem;
  }

  @media (max-width: 768px) {
    .particle-column {
      min-width: 100%;
    }
  }
</style>
