const path = require('path');

const { ProvidePlugin } = require('webpack')

module.exports = {
    entry: './src/index.ts',
    mode: 'production',
    plugins: [
        new ProvidePlugin({
            Buffer: ['buffer', 'Buffer'],
        }),
        new ProvidePlugin({
            process: 'process/browser',
        }),
    ],
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: 'ts-loader',
                exclude: /node_modules/,
            },
        ],
    },
    resolve: {
        extensions: ['.tsx', '.ts', '.js'],
        fallback: {
            buffer: require.resolve('buffer'),
        },
    },
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, '../assets/js'),
    },
};
