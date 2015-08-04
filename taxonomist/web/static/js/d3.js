var margin = {top: 0, right: 0, bottom: 0, left: 0},
    width = parseInt(d3.select('#friend_graph').style('width'), 10) - margin.left - margin.right,
    height = 300 - margin.top - margin.bottom,
    link,
    node;

var x = d3.scale.linear()
    .domain([0,width])
    .range([0,width]);

var y = d3.scale.linear()
    .domain([0,height])
    .range([0,height]);

var zoom = d3.behavior.zoom()
    .scaleExtent([0.1,10])
    .on("zoom", zoomed)
    .x(x)
    .y(y);

var force = d3.layout.force()
    .linkDistance(25)
    .friction(0.8)
    .charge(-75)
    .gravity(0.2)
    .size([width, height]);

var svg = d3.select("#friend_graph").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    // .on("click", function() { console.log(d3.mouse(this)); })
    // .call(zoom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

function scale(bounds) {
    var dx = bounds[1][0] - bounds[0][0],
        dy = bounds[1][1] - bounds[0][1],
        x = (bounds[0][0] + bounds[1][0]) / 2,
        y = (bounds[0][1] + bounds[1][1]) / 2,
        scale = .95 / Math.max(dx / width, dy / height),
        translate = [width / 2 - scale * x, height / 2 - scale * y];

    // svg.transition()
    //     .duration(750)
    //     .call(zoom.translate(translate).scale(scale).event);
    zoom.translate(translate).scale(scale);
}

function zoomed() {
    console.log("zoom", d3.event.translate, d3.event.scale);

    tick();
}

function tick() {
    var xBounds = d3.extent(node.data(), function(d) { return d.x; }),
        yBounds = d3.extent(node.data(), function(d) { return d.y; });

    scale([[xBounds[0],yBounds[0]], [xBounds[1],yBounds[1]]]);

    link.attr("x1", function(d) { return x(d.source.x); })
        .attr("y1", function(d) { return y(d.source.y); })
        .attr("x2", function(d) { return x(d.target.x); })
        .attr("y2", function(d) { return y(d.target.y); });

    node.attr("cx", function(d) { return x(d.x); })
        .attr("cy", function(d) { return y(d.y); });
}

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

  // node.append("title")
  //     .text(function(d) { return d.sceen_name; });

  force.on("tick", tick);
});

d3.timer(function() {
  force.stop();
}, 10*1000);
