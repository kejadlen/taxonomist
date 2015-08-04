var Editor = React.createClass({
  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col-md-12">
            <h1>Editor</h1>
          </div>
        </div>
      </div>
    );
  }
});

var Options = React.createClass({
  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col-md-12">
            <h1>Options</h1>
          </div>
        </div>
        <Editor />
      </div>
    );
  }
});

var Filter = React.createClass({
  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col-md-12">
            <h1>Filter</h1>
          </div>
        </div>
        <Options />
      </div>
    );
  }
});

var FriendGraph = React.createClass({
  render: function() {
    return (
      <div id="friend_graph"></div>
    )
  }
});

var Taxonomist = React.createClass({
  render: function() {
    return (
      <div className="row">
        <div className="col-md-4">
          <Filter />
        </div>
        <div className="col-md-8">
          <FriendGraph />
        </div>
      </div>
    );
  }
});

React.render(
  <Taxonomist />,
  document.getElementById("taxonomist")
);

// var InteractionFilter = React.createClass({
//   key: "ohai",
//   render: function() {
//     return (
//       <h2>Interactions</h2>
//     );
//   }
// });

// var Filters = React.createClass({
//   handleClick: function(filter) {
//     console.log(filter);
//   },
//   render: function() {
//     var filters = [InteractionFilter];
//     return (
//       <ul>
//         {filters.map(function(filter, i) {
//           console.log(filter);
//           return (
//             <li key={i}>{filter.key}</li>
//           );
//         }, this)}
//       </ul>
//     );
//   }
// });

// React.render(
//   <Filters />,
//   document.getElementById("filter")
// );
