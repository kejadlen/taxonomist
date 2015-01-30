var width = parseInt(d3.select('#friend_graph').style('width'), 10),
    height = 400,
    link,
    node;

var x = d3.scale.linear()
    .domain([0,width])
    .range([0,width]);
var y = d3.scale.linear()
    .domain([0,height])
    .range([0,height]);

var zoomer = d3.behavior.zoom()
    .scaleExtent([0.1,10])
    .on("zoom", zoom)
    .x(x)
    .y(y);

function zoom() {
    // console.log("zoom", d3.event.translate, d3.event.scale);
    tick();
}

function tick() {
    link.attr("x1", function(d) { return x(d.source.x); })
        .attr("y1", function(d) { return y(d.source.y); })
        .attr("x2", function(d) { return x(d.target.x); })
        .attr("y2", function(d) { return y(d.target.y); });

    node.attr("cx", function(d) { return x(d.x); })
        .attr("cy", function(d) { return y(d.y); });

    x.domain(d3.extent(node.data(), function(d) { return d.x; }))
    y.domain(d3.extent(node.data(), function(d) { return d.y; }))
}

var force = d3.layout.force()
    .linkDistance(25)
    .friction(0.8)
    .charge(-75)
    .gravity(0.2)
    .size([width, height]);

var svg = d3.select("#friend_graph").append("svg")
    .attr("width", width)
    .attr("height", height);
    // .call(zoomer);

d3.json("friend_graph.json", function(error, graph) {
  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start();

  link = svg.selectAll(".link")
      .data(graph.links)
    .enter().append("line")
      .attr("class", "link");

  node = svg.selectAll(".node")
      .data(graph.nodes)
    .enter().append("circle")
      .attr("class", "node")
      .attr("r", 2);

  node.append("title")
      .text(function(d) { return d.sceen_name; });

  force.on("tick", tick)
});
