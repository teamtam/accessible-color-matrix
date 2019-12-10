module.exports = {
  entry: __dirname + '/src/index.js',
  output: {
    path: __dirname + '/static',
    filename: 'bundle.js'
  },
  resolve: {
    modules: ['node_modules'],
    extensions: ['*', '.js', '.elm']
  },
  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      loader: 'elm-webpack-loader'
    }],
    noParse: /\.elm$/
  },
  devServer: {
    inline: true,
    stats: 'errors-only'
  }
};
