<script>
  let apiUrl = "http://127.0.0.1:8000";
  let particles = ["が", "を", "に", "で", "から", "より", "と", "へ"];
  let results = [];
  let noun = "時間";
  let corpusNorm;
  fetch(apiUrl + "/corpus/norm/")
    .then((response) => response.json())
    .then((data) => {
      corpusNorm = data;
    });

  function getNPVs() {
    fetch(apiUrl + "/npv/noun/" + noun)
      .then((response) => response.json())
      .then((data) => {
        results = data;
      });
  }

  $: console.log(corpusNorm);

  $: d = Object.fromEntries(
    particles.map((particle) => {
      return [
        particle,
        results.filter((d) => {
          return d.p == particle;
        }),
      ];
    })
  );
  $: console.log(d);

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
      on:change={getNPVs}
      on:keypress={(e) => {
        if (e.charCode === 13) getNPVs();
      }}
    />
  </label>
  <div class="columns">
    {#each Object.entries(d) as [particle, collocates]}
      <div>
        <p>{particle}</p>
        <ul>
          {#each collocates as { v, frequency, corpus }}
            <li>
              <svg
                ><rect
                  fill="hotpink"
                  width={((frequency * corpusNorm[corpus]) /
                    getMax(collocates)) *
                    100.0}
                /></svg
              >
              {v}, {corpus}
            </li>
          {/each}
        </ul>
      </div>
    {/each}
  </div>
</main>

<style>
  main {
    text-align: center;
    padding: 1em;
    max-width: 240px;
    margin: 0 auto;
  }

  h1 {
    color: #ff3e00;
    text-transform: uppercase;
    font-size: 4em;
    font-weight: 100;
  }

  div.columns {
    display: flex;
    flex-flow: row wrap;
    flex-basis: 10em;
    flex-grow: 0;
    flex-shrink: 0;
    column-gap: 5px;
  }

  ul {
    list-style: none;
    text-align: left;
  }

  li {
    height: 1.2em;
  }

  svg {
    height: 1.4em;
    position: absolute;
    display: inline;
    z-index: -1;
  }

  rect {
    height: 1.4em;
  }

  @media (min-width: 640px) {
    main {
      max-width: none;
    }
  }
</style>
