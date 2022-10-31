const search = document.querySelector("input#search");

particles = ["が", "を", "に", "で", "から", "より", "と", "へ"];

var vlSpec = {
  $schema: "https://vega.github.io/schema/vega-lite/v5.json",
  data: {
    values: {}, // ここにデータを入れ替える
  },
  facet: {
    column: {
      field: "p",
      type: "nominal",
      sort: particles,
    },
  },
  resolve: {
    scale: {
      //"x": "independent",
      y: "independent",
    },
  },
  width: "container",
  spec: {
    mark: "bar",
    encoding: {
      y: { field: "v", type: "nominal", axis: null, sort: { field: "order" } },
      "order": {"field": "f", "type": "quantitative", "sort": "descending"}
    },
    layer: [
      {
        mark: { type: "bar", color: "#ddd" },
        encoding: {
          x: {
            type: "quantitative",
            field: "f",
            title: "frequency",
          },
        },
      },
      {
        mark: { type: "text", align: "left", x: 4 },
        encoding: {
          text: { field: "v" },
          detail: { field: "v" },
          sort: { field: "x" },
        },
      },
    ],
  },
};

// Embed the visualization in the container with id `vis`
vegaEmbed("#vis", vlSpec);

function get_npv(noun) {
  console.log(noun);

  fetch("http://127.0.0.1:8000/npv/noun/" + noun)
    .then((response) => response.json())
    .then((data) => {
      vlSpec.data.values = data.results;
      vegaEmbed("#vis", vlSpec);
    });
}

// form検索
function searchInput(e) {
    // get_npv(search.value);
    e.preventDefault();
}

// Instant検索
search.addEventListener("input", (e) => {
  get_npv(e.target.value);
});
