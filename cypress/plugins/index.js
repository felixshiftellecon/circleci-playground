/// <reference types="cypress" />

const fs = require('fs-extra')
const path = require('path')

function getConfigurationByFile(file) {
  const pathToConfigFile = path.resolve('cypress', 'config', `${file}.config.json`)

  return fs.readJson(pathToConfigFile)
}

module.exports = (on, config) => {
  const file = config.env.configFile || 'dev'
  const baseUrl = config.env.baseUrl || null;

  on('task', {
    log (message) {
      console.log(message)
      return null
    }
  })

  if (baseUrl) {
    config.baseUrl = baseUrl;
  }

  return getConfigurationByFile(file), config
}
