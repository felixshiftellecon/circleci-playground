describe('Visit A Website', () => {

  beforeEach(function() {
    Cypress.log({
      name: 'show config',
      // shorter name for the Command Log
      message: `${Object.key}, ${Object.value}`,
      consoleProps: () => {
        // return an object which will
        // print to dev tools console on click
        return {
          Key: Object.key,
          Value: Object.value,
          'Config': Cypress.config(),
        }
      }
    })
  })

  it('visits the base url with /', () => {
    cy.visit('/')
  })

  it('visits the base url with Cypress.config(baseUrl)', () => {
    cy.visit(Cypress.config('baseUrl'))
  })

  it('visits the base url with Cypress.config().baseUrl', () => {
    cy.visit(Cypress.config().baseUrl)
  })
})