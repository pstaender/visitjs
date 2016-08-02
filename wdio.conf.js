exports.config = {

    specs: [
        './test/specs/*'
    ],
    // Patterns to exclude.
    exclude: [
        // 'path/to/excluded/files'
    ],
    plugins: {
      'wdio-screenshot': {}
    },
    maxInstances: 10,
    capabilities: [
      {
        maxInstances: 5,
        browserName: 'phantomjs'
      },
      // {
      //   maxInstances: 5,
      //   browserName: 'chrome'
      // },
    // {
    //     maxInstances: 5,
    //     browserName: 'firefox',
    // }
    ],
    services: ['selenium-standalone'],
    sync: true,
    logLevel: 'silent',
    coloredLogs: true,
    screenshotPath: './errorShots/',
    baseUrl: 'http://localhost:3300',
    waitforTimeout: 10000,
    connectionRetryTimeout: 90000,
    connectionRetryCount: 3,
    framework: 'mocha',
    reporters: ['spec'],
    mochaOpts: {
        ui: 'bdd',
        compilers: ['coffee:coffee-script/register']
    },

}
